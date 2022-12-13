// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ILightmEquippable.sol";
import "../library/ValidatorLib.sol";
import "./RMRKNestableInternal.sol";
import "./RMRKMultiAssetInternal.sol";

abstract contract RMRKNestableMultiAssetInternal is
    RMRKNestableInternal,
    RMRKMultiAssetInternal
{
    using RMRKLib for uint64[];

    // ------------------------ Function conflicts resolve ------------------------

    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override(ERC721Internal, RMRKNestableInternal)
        returns (bool)
    {
        return RMRKNestableInternal._exists(tokenId);
    }

    function _ownerOf(uint256 tokenId)
        internal
        view
        virtual
        override(ERC721Internal, RMRKNestableInternal)
        returns (address)
    {
        return RMRKNestableInternal._ownerOf(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721Internal, RMRKMultiAssetInternal)
    {
        RMRKMultiAssetInternal._burn(tokenId);
    }

    function _burn(uint256 tokenId, uint256 maxChildrenBurns)
        internal
        virtual
        override
        returns (uint256)
    {
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
        _approve(address(0), tokenId);
        _approveForAssets(address(0), tokenId);
        _cleanApprovals(tokenId);

        NestableStorage.State storage ns = getNestableState();
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

    function _mint(address to, uint256 tokenId)
        internal
        virtual
        override(ERC721Internal, RMRKNestableInternal)
    {
        RMRKNestableInternal._mint(to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Internal, RMRKNestableInternal) {
        RMRKNestableInternal._transfer(from, to, tokenId);
    }

    function _tokenURI(uint256 tokenId)
        internal
        view
        virtual
        override(ERC721Internal, RMRKMultiAssetInternal)
        returns (string memory)
    {
        return RMRKMultiAssetInternal._tokenURI(tokenId);
    }
}
