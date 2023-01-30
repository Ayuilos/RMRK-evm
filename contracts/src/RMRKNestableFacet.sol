// SPDX-License-Identifier: Apache-2.0

// RMRKNestable facet style which could be used alone

pragma solidity ^0.8.15;

import "./interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IRMRKNestable.sol";
import "./library/RMRKLib.sol";
import "./internalFunctionSet/RMRKNestableInternal.sol";

contract RMRKNestableFacet is
    IERC165,
    IERC721,
    IERC721Metadata,
    IRMRKNestable,
    RMRKNestableInternal
{
    using RMRKLib for uint256;
    using Address for address;
    using Strings for uint256;

    constructor(string memory name_, string memory symbol_) {
        ERC721Storage.State storage s = getState();
        s._name = name_;
        s._symbol = symbol_;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IRMRKNestable).interfaceId;
    }

    // ------------------------ Metadata ------------------------

    /**
     * @inheritdoc IERC721Metadata
     */
    function name() public view virtual override returns (string memory) {
        return getState()._name;
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function symbol() public view virtual override returns (string memory) {
        return getState()._symbol;
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _tokenURI(tokenId);
    }

    // ------------------------ Ownership ------------------------

    /**
     * @inheritdoc IRMRKNestable
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(IERC721, IRMRKNestable)
        returns (address)
    {
        return _ownerOf(tokenId);
    }

    /**
     * @inheritdoc IRMRKNestable
     */
    function directOwnerOf(uint256 tokenId)
        public
        view
        virtual
        returns (
            address,
            uint256,
            bool
        )
    {
        return _directOwnerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balanceOf(owner);
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ERC721ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert ERC721ApproveCallerIsNotOwnerNorApprovedForAll();

        _approve(to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return _getApproved(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _isApprovedForAll(owner, operator);
    }

    // ------------------------ BURNING ------------------------

    /**
     * @notice Used to burn a given token.
     * @dev In case the token has any child tokens, the execution will be reverted.
     * @param tokenId ID of the token to burn
     */
    function burn(uint256 tokenId)
        public
        virtual
        onlyApprovedOrDirectOwner(tokenId)
        returns (uint256)
    {
        return _burn(tokenId, 0);
    }

    /**
     * @inheritdoc IRMRKNestable
     */
    function burn(uint256 tokenId, uint256 maxRecursiveBurns)
        public
        virtual
        onlyApprovedOrDirectOwner(tokenId)
        returns (uint256)
    {
        return _burn(tokenId, maxRecursiveBurns);
    }

    // ------------------------ TRANSFERING ------------------------

    /**
     * @dev This method is a shorthand of `transferFrom` with setting `from` to `msg.sender`
     */
    function transfer(address to, uint256 tokenId) public virtual {
        transferFrom(_msgSender(), to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _transfer(from, to, tokenId);
    }

    /**
     * @inheritdoc IRMRKNestable
     */
    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _nestTransfer(from, to, tokenId, destinationId, data);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override onlyApprovedOrDirectOwner(tokenId) {
        _safeTransfer(from, to, tokenId, data);
    }

    // ------------------------ CHILD MANAGEMENT PUBLIC ------------------------

    /**
     * @inheritdoc IRMRKNestable
     */
    function addChild(
        uint256 parentTokenId,
        uint256 childTokenId,
        bytes memory data
    ) public virtual {
        _addChild(parentTokenId, childTokenId, data);
    }

    /**
     * @inheritdoc IRMRKNestable
     */
    function acceptChild(
        uint256 tokenId,
        uint256, // We wanna support raw RMRK interface, but we will ignore this parameter in our own implementation
        address childContractAddress,
        uint256 childTokenId
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _acceptChild(tokenId, childContractAddress, childTokenId);
    }

    /**
     * @inheritdoc IRMRKNestable
     */
    function rejectAllChildren(uint256 tokenId, uint256 maxRejections)
        public
        virtual
        onlyApprovedOrOwner(tokenId)
    {
        _rejectAllChildren(tokenId, maxRejections);
    }

    /**
     * @inheritdoc IRMRKNestable
     */
    function transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        uint256, // We wanna support raw RMRK interface, but we will ignore this parameter in our own implementation
        address childContractAddress,
        uint256 childTokenId,
        bool isPending,
        bytes memory data
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _transferChild(
            tokenId,
            to,
            destinationId,
            childContractAddress,
            childTokenId,
            isPending,
            data
        );
    }

    // ------------------------ CHILD MANAGEMENT GETTERS ------------------------

    /**
     * @inheritdoc IRMRKNestable
     */
    function childrenOf(uint256 parentTokenId)
        public
        view
        returns (Child[] memory)
    {
        return _childrenOf(parentTokenId);
    }

    /**
     * @inheritdoc IRMRKNestable
     */
    function pendingChildrenOf(uint256 parentTokenId)
        public
        view
        returns (Child[] memory)
    {
        return _pendingChildrenOf(parentTokenId);
    }

    /**
     * @inheritdoc IRMRKNestable
     */
    function childOf(uint256 parentTokenId, uint256 index)
        external
        view
        returns (Child memory)
    {
        return _childOf(parentTokenId, index);
    }

    /**
     * @inheritdoc IRMRKNestable
     */
    function pendingChildOf(uint256 parentTokenId, uint256 index)
        external
        view
        returns (Child memory)
    {
        return _pendingChildOf(parentTokenId, index);
    }
}
