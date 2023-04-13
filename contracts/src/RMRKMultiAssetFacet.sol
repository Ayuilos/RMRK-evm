// SPDX-License-Identifier: Apache-2.0

// RMRKMR facet style which could be used alone

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./interfaces/IERC721Metadata.sol";

import "./internalFunctionSet/RMRKMultiAssetInternal.sol";
import "./interfaces/IRMRKMultiAsset.sol";
import "./library/RMRKLib.sol";
import "./library/RMRKMultiAssetRenderUtils.sol";

// !!!
// Before use, make sure you know the description below
// !!!
/**
    @dev NOTE that MultiAsset take NFT as a real unique item on-chain,
    so if you `burn` a NFT, it means that you NEVER wanna `mint` it again,
    if you do so, you are trying to raising the soul of a dead man
    (the `activeAssets` etc. of this burned token will not be removed when `burn`),
    instead of creating a new life by using a empty shell.
    You are responsible for any unknown consequences of this action, so take care of
    `mint` logic in your own implementer.
 */

contract RMRKMultiAssetFacet is
    IERC721,
    IERC721Metadata,
    IRMRKMultiAsset,
    RMRKMultiAssetInternal
{
    using RMRKLib for uint256;
    using RMRKLib for uint64[];
    using RMRKLib for uint128[];
    using Address for address;
    using Strings for uint256;

    constructor(string memory name_, string memory symbol_) {
        ERC721Storage.State storage s = getState();
        s._name = name_;
        s._symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IRMRKMultiAsset).interfaceId;
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
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return _ownerOf(tokenId);
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

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _onlyApprovedOrOwner(tokenId);

        _transfer(from, to, tokenId);
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
    ) public virtual override {
        _onlyApprovedOrOwner(tokenId);
        _safeTransfer(from, to, tokenId, data);
    }

    // ------------------------ RESOURCES ------------------------

    /**
     * @inheritdoc IRMRKMultiAsset
     */
    function acceptAsset(
        uint256 tokenId,
        uint256,
        uint64 assetId
    ) external virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _acceptAsset(tokenId, assetId);
    }

    /**
     * @inheritdoc IRMRKMultiAsset
     */
    function rejectAsset(
        uint256 tokenId,
        uint256,
        uint64 assetId
    ) external virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _rejectAsset(tokenId, assetId);
    }

    /**
     * @inheritdoc IRMRKMultiAsset
     */
    function rejectAllAssets(uint256 tokenId, uint256 maxRejections)
        external
        virtual
        onlyApprovedForAssetsOrOwner(tokenId)
    {
        _rejectAllAssets(tokenId, maxRejections);
    }

    /**
     * @inheritdoc IRMRKMultiAsset
     */
    function setPriority(uint256 tokenId, uint64[] memory priorities)
        external
        virtual
        onlyApprovedForAssetsOrOwner(tokenId)
    {
        _setPriority(tokenId, priorities);
    }

    /**
     * @inheritdoc IRMRKMultiAsset
     */
    function approveForAssets(address to, uint256 tokenId) external virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert RMRKApprovalForAssetsToCurrentOwner();

        if (
            _msgSender() != owner &&
            !_isApprovedForAllForAssets(owner, _msgSender())
        ) revert RMRKApproveForAssetsCallerIsNotOwnerNorApprovedForAll();

        _approveForAssets(to, tokenId);
    }

    /**
     * @inheritdoc IRMRKMultiAsset
     */
    function setApprovalForAllForAssets(address operator, bool approved)
        external
        virtual
    {
        address owner = _msgSender();
        if (owner == operator) revert RMRKApproveForAssetsToCaller();

        _setApprovalForAllForAssets(owner, operator, approved);
    }

    /**
     * @inheritdoc IRMRKMultiAsset
     */
    function getAssetMetadata(uint256 tokenId, uint64 assetId)
        public
        view
        virtual
        returns (string memory)
    {
        return _getAssetMetadata(tokenId, assetId);
    }

    /**
     * @inheritdoc IRMRKMultiAsset
     */
    function getActiveAssets(uint256 tokenId)
        public
        view
        virtual
        returns (uint64[] memory)
    {
        return _getActiveAssets(tokenId);
    }

    /**
     * @inheritdoc IRMRKMultiAsset
     */
    function getPendingAssets(uint256 tokenId)
        public
        view
        virtual
        returns (uint64[] memory)
    {
        return _getPendingAssets(tokenId);
    }

    /**
     * @inheritdoc IRMRKMultiAsset
     */
    function getActiveAssetPriorities(uint256 tokenId)
        public
        view
        virtual
        returns (uint64[] memory)
    {
        return _getActiveAssetPriorities(tokenId);
    }

    /**
     * @inheritdoc IRMRKMultiAsset
     */
    function getAssetReplacements(uint256 tokenId, uint64 assetId)
        public
        view
        virtual
        returns (uint64)
    {
        return _getAssetReplacements(tokenId, assetId);
    }

    /**
     * @inheritdoc IRMRKMultiAsset
     */
    function getApprovedForAssets(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        return _getApprovedForAssets(tokenId);
    }

    /**
     * @inheritdoc IRMRKMultiAsset
     */
    function isApprovedForAllForAssets(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return _isApprovedForAllForAssets(owner, operator);
    }
}
