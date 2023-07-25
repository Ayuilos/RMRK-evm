// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/RMRKLib.sol";
import "../interfaces/IRMRKNestable.sol";
import "./ERC721Internal.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {NestableStorage} from "./Storage.sol";

error RMRKChildIndexOutOfRange();
error RMRKDuplicateAdd();
error RMRKInvalidChildReclaim();
error RMRKIsNotContract();
error RMRKIsNotNestableImplementer();
error RMRKMaxPendingChildrenReached();
error RMRKMaxRecursiveBurnsReached(address childContract, uint256 childTokenId);
error RMRKMintToNonRMRKImplementer();
error RMRKNestableTooDeep();
error RMRKNestableTransferToDescendant();
error RMRKNestableTransferToNonRMRKNestableImplementer();
error RMRKNestableTransferToSelf();
error RMRKNotApprovedOrDirectOwner();
error RMRKUnexpectedNumberOfChildren();
error RMRKParentChildMismatch();
error RMRKPendingChildIndexOutOfRange();

abstract contract RMRKNestableInternal is
    IRMRKNestableEventsAndStruct,
    ERC721Internal
{
    using RMRKLib for uint256;
    using Address for address;

    uint256 private constant _MAX_LEVELS_TO_CHECK_FOR_INHERITANCE_LOOP = 100;

    function getNestableState()
        internal
        pure
        returns (NestableStorage.State storage)
    {
        return NestableStorage.getState();
    }

    // ------------------------ Ownership ------------------------

    function _ownerOf(
        uint256 tokenId
    ) internal view virtual override returns (address) {
        (address owner, uint256 ownerTokenId, bool isNft) = _directOwnerOf(
            tokenId
        );

        if (isNft) {
            owner = IRMRKNestable(owner).ownerOf(ownerTokenId);
        }
        if (owner == address(0)) revert ERC721InvalidTokenId();
        return owner;
    }

    /**
     * @dev Returns the immediate provenance data of the current RMRK NFT. In the event the NFT is owned
     * by a wallet, tokenId will be zero and isNft will be false. Otherwise, the returned data is the
     * contract address and tokenID of the owner NFT, as well as its isNft flag.
     */
    function _directOwnerOf(
        uint256 tokenId
    ) internal view virtual returns (address, uint256, bool) {
        DirectOwner storage owner = getNestableState()._DirectOwners[tokenId];
        if (owner.ownerAddress == address(0)) revert ERC721InvalidTokenId();

        return (owner.ownerAddress, owner.tokenId, owner.tokenId != 0);
    }

    function _isApprovedOrDirectOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        (address owner, uint256 parentTokenId, ) = _directOwnerOf(tokenId);
        if (parentTokenId != 0) {
            return (spender == owner);
        }
        return (spender == owner ||
            _isApprovedForAll(owner, spender) ||
            _getApproved(tokenId) == spender);
    }

    /**
     * @notice Internal function for checking token ownership relative to immediate parent.
     * @dev This does not delegate to ownerOf, which returns the root owner.
     * Reverts if caller is not immediate owner.
     * Used for parent-scoped transfers.
     * @param tokenId tokenId to check owner against.
     */
    function _onlyApprovedOrDirectOwner(uint256 tokenId) private view {
        if (!_isApprovedOrDirectOwner(_msgSender(), tokenId))
            revert RMRKNotApprovedOrDirectOwner();
    }

    modifier onlyApprovedOrDirectOwner(uint256 tokenId) {
        _onlyApprovedOrDirectOwner(tokenId);
        _;
    }

    /**
     * @dev Returns all confirmed children
     */

    function _childrenOf(
        uint256 parentTokenId
    ) internal view returns (Child[] memory) {
        Child[] memory children = getNestableState()._activeChildren[
            parentTokenId
        ];
        return children;
    }

    function _pendingChildrenOf(
        uint256 parentTokenId
    ) internal view returns (Child[] memory) {
        Child[] memory pendingChildren = getNestableState()._pendingChildren[
            parentTokenId
        ];
        return pendingChildren;
    }

    function _childOf(
        uint256 parentTokenId,
        uint256 index
    ) internal view returns (Child memory) {
        _isOverLength(parentTokenId, index, false);

        Child memory child = getNestableState()._activeChildren[parentTokenId][
            index
        ];
        return child;
    }

    function _pendingChildOf(
        uint256 parentTokenId,
        uint256 index
    ) internal view returns (Child memory) {
        _isOverLength(parentTokenId, index, true);

        Child memory child = getNestableState()._pendingChildren[parentTokenId][
            index
        ];
        return child;
    }

    function _hasChild(
        uint256 tokenId,
        address childContract,
        uint256 childTokenId
    ) internal view returns (bool found, bool isPending, uint256 index) {
        _requireMinted(tokenId);

        NestableStorage.State storage ns = getNestableState();

        uint256 _index = ns._posInChildArray[childContract][childTokenId];

        if (_index > 0) {
            found = true;
            index = _index;

            Child memory _pendingChild = ns._pendingChildren[tokenId][index];

            if (
                _pendingChild.contractAddress == childContract &&
                _pendingChild.tokenId == childTokenId
            ) {
                isPending = true;
            }
        } else {
            (address parentContract, , bool isNft) = IRMRKNestable(
                childContract
            ).directOwnerOf(childTokenId);

            if (isNft && parentContract == address(this)) {
                if (ns._activeChildren[tokenId].length > 0) {
                    Child memory child = ns._activeChildren[tokenId][0];
                    if (
                        child.contractAddress == childContract &&
                        child.tokenId == childTokenId
                    ) {
                        found = true;
                        return (found, isPending, index);
                    }
                }

                if (ns._pendingChildren[tokenId].length > 0) {
                    Child memory pendingChild = ns._pendingChildren[tokenId][0];
                    if (
                        pendingChild.contractAddress == childContract &&
                        pendingChild.tokenId == childTokenId
                    ) {
                        found = true;
                        isPending = true;
                    }
                }
            }
        }
    }

    // ------------------------ MINTING ------------------------

    function _mint(
        address to,
        uint256 tokenId,
        bool isNft,
        uint256 destinationId,
        bytes memory data
    ) internal {
        if (to == address(0)) revert ERC721MintToTheZeroAddress();
        if (_exists(tokenId)) revert ERC721TokenAlreadyMinted();

        if (isNft) {
            _isNestableContract(to, 1);
        }

        _beforeTokenTransfer(address(0), to, tokenId);
        _beforeNestedTokenTransfer(
            address(0),
            to,
            0,
            destinationId,
            tokenId,
            data
        );

        getState()._balances[to] += 1;

        if (isNft) {
            getNestableState()._DirectOwners[tokenId] = DirectOwner({
                ownerAddress: to,
                tokenId: destinationId
            });

            _sendToNFT(to, destinationId, tokenId, data);
        } else {
            getNestableState()._DirectOwners[tokenId] = DirectOwner({
                ownerAddress: to,
                tokenId: 0
            });
        }

        emit Transfer(address(0), to, tokenId);
        emit NestTransfer(address(0), to, 0, destinationId, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
        _afterNestedTokenTransfer(
            address(0),
            to,
            0,
            destinationId,
            tokenId,
            data
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId, false, 0, "");
    }

    function _mint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId, false, 0, data);
    }

    function _nestMint(
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId, true, destinationId, data);
    }

    function _sendToNFT(
        address to,
        uint256 destinationId,
        uint256 tokenId,
        bytes memory data
    ) private {
        IRMRKNestable destContract = IRMRKNestable(to);

        destContract.addChild(destinationId, tokenId, data);
    }

    // ------------------------ BURNING ------------------------

    function _burn(
        uint256 tokenId,
        uint256 maxChildrenBurns
    ) internal virtual returns (uint256) {
        (address immediateOwner, uint256 parentId, ) = _directOwnerOf(tokenId);
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);
        _beforeNestedTokenTransfer(
            immediateOwner,
            address(0),
            parentId,
            0,
            tokenId,
            ""
        );

        {
            ERC721Storage.State storage s = getState();
            s._balances[immediateOwner] -= 1;
            delete s._tokenApprovals[tokenId];
        }

        NestableStorage.State storage ns = getNestableState();

        _approve(address(0), tokenId);
        _cleanApprovals(tokenId);

        Child[] memory children = ns._activeChildren[tokenId];

        delete ns._activeChildren[tokenId];
        delete ns._pendingChildren[tokenId];

        uint256 totalChildBurns;
        {
            uint256 pendingRecursiveBurns;
            uint256 length = children.length; //gas savings
            for (uint256 i; i < length; ) {
                if (totalChildBurns >= maxChildrenBurns) {
                    revert RMRKMaxRecursiveBurnsReached(
                        children[i].contractAddress,
                        children[i].tokenId
                    );
                }

                delete ns._posInChildArray[children[i].contractAddress][
                    children[i].tokenId
                ];

                unchecked {
                    // At this point we know pendingRecursiveBurns must be at least 1
                    pendingRecursiveBurns = maxChildrenBurns - totalChildBurns;
                }
                // We substract one to the next level to count for the token being burned, then add it again on returns
                // This is to allow the behavior of 0 recursive burns meaning only the current token is deleted.
                totalChildBurns +=
                    IRMRKNestable(children[i].contractAddress).burn(
                        children[i].tokenId,
                        pendingRecursiveBurns - 1
                    ) +
                    1;
                unchecked {
                    ++i;
                }
            }
        }
        // Can't remove before burning child since child will call back to get root owner
        delete ns._DirectOwners[tokenId];

        _afterTokenTransfer(owner, address(0), tokenId);
        _afterNestedTokenTransfer(
            immediateOwner,
            address(0),
            parentId,
            0,
            tokenId,
            ""
        );
        emit Transfer(owner, address(0), tokenId);
        emit NestTransfer(immediateOwner, address(0), parentId, 0, tokenId);

        return totalChildBurns;
    }

    // ------------------------ TRANSFERING ------------------------

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        _transfer(from, to, tokenId, false, 0, "");
    }

    function _nestTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId, true, destinationId, data);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        bool isNft,
        uint256 destinationId,
        bytes memory data
    ) private {
        (address directOwner, uint256 fromTokenId, ) = _directOwnerOf(tokenId);
        if (directOwner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();
        if (isNft) {
            _isNestableContract(to, 2);

            if (to == address(this) && tokenId == destinationId) {
                revert RMRKNestableTransferToSelf();
            }

            _checkForInheritanceLoop(tokenId, to, destinationId);
        }

        _beforeTokenTransfer(from, to, tokenId);
        _beforeNestedTokenTransfer(
            directOwner,
            to,
            fromTokenId,
            destinationId,
            tokenId,
            data
        );

        getState()._balances[from] -= 1;
        _updateOwnerAndClearApprovals(tokenId, isNft ? destinationId : 0, to);
        getState()._balances[to] += 1;

        if (isNft)
            _sendToNFT(to, destinationId, tokenId, data);

        emit Transfer(from, to, tokenId);
        emit NestTransfer(from, to, fromTokenId, destinationId, tokenId);

        _afterTokenTransfer(from, to, tokenId);
        _afterNestedTokenTransfer(
            from,
            to,
            fromTokenId,
            destinationId,
            tokenId,
            data
        );
    }

    function _checkForInheritanceLoop(
        uint256 currentId,
        address targetContract,
        uint256 targetId
    ) private view {
        for (uint256 i; i < _MAX_LEVELS_TO_CHECK_FOR_INHERITANCE_LOOP; ) {
            (
                address nextOwner,
                uint256 nextOwnerTokenId,
                bool isNft
            ) = IRMRKNestable(targetContract).directOwnerOf(targetId);
            // If there's a final address, we're good. There's no loop.
            if (!isNft) {
                return;
            }
            // Ff the current nft is an ancestor at some point, there is an inheritance loop
            if (nextOwner == address(this) && nextOwnerTokenId == currentId) {
                revert RMRKNestableTransferToDescendant();
            }
            // We reuse the parameters to save some contract size
            targetContract = nextOwner;
            targetId = nextOwnerTokenId;
            unchecked {
                ++i;
            }
        }
        revert RMRKNestableTooDeep();
    }

    function _updateOwnerAndClearApprovals(
        uint256 tokenId,
        uint256 destinationId,
        address to
    ) internal {
        getNestableState()._DirectOwners[tokenId] = DirectOwner({
            ownerAddress: to,
            tokenId: destinationId
        });

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _cleanApprovals(tokenId);
    }

    function _cleanApprovals(uint256 tokenId) internal virtual {}

    function _exists(
        uint256 tokenId
    ) internal view virtual override returns (bool) {
        return
            getNestableState()._DirectOwners[tokenId].ownerAddress !=
            address(0);
    }

    // ------------------------ CHILD MANAGEMENT ------------------------
    function _addChild(
        uint256 parentTokenId,
        uint256 childTokenId,
        bytes memory data
    ) internal virtual {
        _requireMinted(parentTokenId);

        address childContractAddress = _msgSender();
        _isNestableContract(childContractAddress, 0);

        (bool isDuplicate, , ) = _hasChild(
            parentTokenId,
            childContractAddress,
            childTokenId
        );
        if (isDuplicate) revert RMRKDuplicateAdd();

        _beforeAddChild(
            parentTokenId,
            childContractAddress,
            childTokenId,
            data
        );

        IRMRKNestable childTokenContract = IRMRKNestable(childContractAddress);
        (address _parentContract, uint256 _parentTokenId, ) = childTokenContract
            .directOwnerOf(childTokenId);
        if (_parentContract != address(this) || _parentTokenId != parentTokenId)
            revert RMRKParentChildMismatch();

        Child memory child = Child({
            contractAddress: childContractAddress,
            tokenId: childTokenId
        });

        _addChildToPending(parentTokenId, child);
        emit ChildProposed(
            parentTokenId,
            getNestableState()._pendingChildren[parentTokenId].length,
            child.contractAddress,
            child.tokenId
        );

        _afterAddChild(parentTokenId, childContractAddress, childTokenId, data);
    }

    function _acceptChild(
        uint256 tokenId,
        address childContractAddress,
        uint256 childTokenId
    ) internal virtual {
        NestableStorage.State storage s = getNestableState();
        uint256 index = s._posInChildArray[childContractAddress][childTokenId];

        Child memory child = s._pendingChildren[tokenId][index];

        _isOverLength(tokenId, index, true);

        if (
            child.contractAddress != childContractAddress ||
            child.tokenId != childTokenId
        ) {
            revert RMRKParentChildMismatch();
        }

        _beforeAcceptChild(tokenId, index, childContractAddress, childTokenId);

        _removeItemByIndexAndUpdateLastChildIndex(
            s._pendingChildren[tokenId],
            index
        );

        _addChildToChildren(tokenId, child);
        emit ChildAccepted(
            tokenId,
            index,
            child.contractAddress,
            child.tokenId
        );

        _afterAcceptChild(tokenId, index, childContractAddress, childTokenId);
    }

    function _transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        address childContractAddress,
        uint256 childTokenId,
        bool isPending,
        bytes memory data
    ) internal virtual {
        NestableStorage.State storage ns = getNestableState();
        uint256 index = ns._posInChildArray[childContractAddress][childTokenId];

        _isOverLength(tokenId, index, isPending);

        Child[] storage children = isPending
            ? ns._pendingChildren[tokenId]
            : ns._activeChildren[tokenId];
        {
        Child memory child = children[index];

        if (
            child.contractAddress != childContractAddress ||
            child.tokenId != childTokenId
        ) {
            revert RMRKParentChildMismatch();
            }
        }

        _beforeTransferChild(
            tokenId,
            index,
            childContractAddress,
            childTokenId,
            isPending,
            data
        );

        _removeItemByIndexAndUpdateLastChildIndex(children, index);
        delete ns._posInChildArray[childContractAddress][childTokenId];

        if (to != address(0)) {
            if (destinationId == 0) {
                IERC721(childContractAddress).safeTransferFrom(
                    address(this),
                    to,
                    childTokenId
                );
            } else {
                IRMRKNestable(childContractAddress).nestTransferFrom(
                    address(this),
                    to,
                    childTokenId,
                    destinationId,
                    data
                );
            }
        }

        emit ChildTransferred(
            tokenId,
            index,
            childContractAddress,
            childTokenId,
            isPending,
            to == address(0)
        );

        _afterTransferChild(
            tokenId,
            index,
            childContractAddress,
            childTokenId,
            isPending,
            data
        );
    }

    /**
     * @dev Adds an instance of Child to the pending children array for tokenId. This is hardcoded to be 128 by default.
     */
    function _addChildToPending(uint256 tokenId, Child memory child) internal {
        NestableStorage.State storage ns = getNestableState();
        uint256 len = ns._pendingChildren[tokenId].length;
        if (len < 128) {
            ns._posInChildArray[child.contractAddress][child.tokenId] = len;
            ns._pendingChildren[tokenId].push(child);
        } else {
            revert RMRKMaxPendingChildrenReached();
        }
    }

    /**
     * @dev Adds an instance of Child to the children array for tokenId.
     */
    function _addChildToChildren(uint256 tokenId, Child memory child) internal {
        NestableStorage.State storage ns = getNestableState();

        ns._posInChildArray[child.contractAddress][child.tokenId] = ns
            ._activeChildren[tokenId]
            .length;

        ns._activeChildren[tokenId].push(child);
    }

    function _rejectAllChildren(
        uint256 tokenId,
        uint256 maxRejections
    ) internal {
        NestableStorage.State storage ns = getNestableState();
        Child[] memory children = ns._pendingChildren[tokenId];

        if (children.length > maxRejections) {
            revert RMRKUnexpectedNumberOfChildren();
        }

        _beforeRejectAllChildren(tokenId);

        for (uint256 i; i < ns._pendingChildren[tokenId].length; ) {
            Child memory child = ns._pendingChildren[tokenId][i];
            address childContract = child.contractAddress;
            uint256 childTokenId = child.tokenId;

            delete ns._posInChildArray[childContract][childTokenId];

            unchecked {
                ++i;
            }
        }

        delete getNestableState()._pendingChildren[tokenId];

        emit AllChildrenRejected(tokenId);
        _afterRejectAllChildren(tokenId);
    }

    // ------------------------ HOOKS ------------------------
    /**
     * @notice Hook that is called before nested token transfer.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token is being transferred
     * @param to Address to which the token is being transferred
     * @param fromTokenId ID of the token from which the given token is being transferred
     * @param toTokenId ID of the token to which the given token is being transferred
     * @param tokenId ID of the token being transferred
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _beforeNestedTokenTransfer(
        address from,
        address to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after nested token transfer.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token was transferred
     * @param to Address to which the token was transferred
     * @param fromTokenId ID of the token from which the given token was transferred
     * @param toTokenId ID of the token to which the given token was transferred
     * @param tokenId ID of the token that was transferred
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _afterNestedTokenTransfer(
        address from,
        address to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is added to the pending tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will receive a new pending child token
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     * @param data Additional data with no specified format
     */
    function _beforeAddChild(
        uint256 tokenId,
        address childAddress,
        uint256 childId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is added to the pending tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has received a new pending child token
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     * @param data Additional data with no specified format
     */
    function _afterAddChild(
        uint256 tokenId,
        address childAddress,
        uint256 childId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is accepted to the active tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param parentId ID of the token that will accept a pending child token
     * @param childIndex Index of the child token to accept in the given parent token's pending children array
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function _beforeAcceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is accepted to the active tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param parentId ID of the token that has accepted a pending child token
     * @param childIndex Index of the child token that was accpeted in the given parent token's pending children array
     * @param childAddress Address of the collection smart contract of the child token that was expected to be located
     *  at the specified index of the given parent token's pending children array
     * @param childId ID of the child token that was expected to be located at the specified index of the given parent
     *  token's pending children array
     */
    function _afterAcceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is transferred from a given child token array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will transfer a child token
     * @param childIndex Index of the child token that will be transferred from the given parent token's children array
     * @param childAddress Address of the collection smart contract of the child token that is expected to be located
     *  at the specified index of the given parent token's children array
     * @param childId ID of the child token that is expected to be located at the specified index of the given parent
     *  token's children array
     * @param isPending A boolean value signifying whether the child token is being transferred from the pending child
     *  tokens array (`true`) or from the active child tokens array (`false`)
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _beforeTransferChild(
        uint256 tokenId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is transferred from a given child token array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has transferred a child token
     * @param childIndex Index of the child token that was transferred from the given parent token's children array
     * @param childAddress Address of the collection smart contract of the child token that was expected to be located
     *  at the specified index of the given parent token's children array
     * @param childId ID of the child token that was expected to be located at the specified index of the given parent
     *  token's children array
     * @param isPending A boolean value signifying whether the child token was transferred from the pending child tokens
     *  array (`true`) or from the active child tokens array (`false`)
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _afterTransferChild(
        uint256 tokenId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called before a pending child tokens array of a given token is cleared.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will reject all of the pending child tokens
     */
    function _beforeRejectAllChildren(uint256 tokenId) internal virtual {}

    /**
     * @notice Hook that is called after a pending child tokens array of a given token is cleared.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has rejected all of the pending child tokens
     */
    function _afterRejectAllChildren(uint256 tokenId) internal virtual {}

    // ------------------------ HELPERS ------------------------

    // For child storage array
    function _removeItemByIndex(Child[] storage array, uint256 index) internal {
        array[index] = array[array.length - 1];
        array.pop();
    }

    function _removeItemByIndexAndUpdateLastChildIndex(
        Child[] storage array,
        uint256 index
    ) internal {
        uint256 len = array.length;
        Child storage lastChild = array[len - 1];
        address lastChildContract = lastChild.contractAddress;
        uint256 lastChildTokenId = lastChild.tokenId;

        // after this operation, the last child will replace the target child position in `_children`/`_pendingChildren`
        _removeItemByIndex(array, index);

        // so have to change last child's index record in `posInChildArray`
        getNestableState()._posInChildArray[lastChildContract][
            lastChildTokenId
        ] = index;
    }

    function _isNestableContract(
        address contractAddress,
        uint256 errorIndex
    ) internal view {
        if (!contractAddress.isContract()) revert RMRKIsNotContract();
        if (
            !IERC165(contractAddress).supportsInterface(
                type(IRMRKNestable).interfaceId
            )
        ) {
            if (errorIndex == 1) {
                revert RMRKMintToNonRMRKImplementer();
            } else if (errorIndex == 2) {
                revert RMRKNestableTransferToNonRMRKNestableImplementer();
            } else {
                revert RMRKIsNotNestableImplementer();
            }
        }
    }

    function _isOverLength(
        uint256 tokenId,
        uint256 index,
        bool isPending
    ) internal view {
        if (isPending) {
            if (getNestableState()._pendingChildren[tokenId].length <= index)
                revert RMRKPendingChildIndexOutOfRange();
        } else {
            if (getNestableState()._activeChildren[tokenId].length <= index)
                revert RMRKChildIndexOutOfRange();
        }
    }
}
