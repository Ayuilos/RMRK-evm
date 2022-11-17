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
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return getState()._name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return getState()._symbol;
    }

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
     * @dev See {IERC721-balanceOf}.
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
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ERC721ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert ERC721ApproveCallerIsNotOwnerNorApprovedForAll();

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
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
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
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
     * @dev See {IERC721-transferFrom}.
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
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
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

    function acceptAsset(uint256 tokenId, uint64 assetId)
        external
        virtual
        onlyApprovedForAssetsOrOwner(tokenId)
    {
        _acceptAsset(tokenId, assetId);
    }

    function rejectAsset(uint256 tokenId, uint64 assetId)
        external
        virtual
        onlyApprovedForAssetsOrOwner(tokenId)
    {
        _rejectAsset(tokenId, assetId);
    }

    function rejectAllAssets(uint256 tokenId)
        external
        virtual
        onlyApprovedForAssetsOrOwner(tokenId)
    {
        _rejectAllAssets(tokenId);
    }

    function setPriority(uint256 tokenId, uint16[] memory priorities)
        external
        virtual
        onlyApprovedForAssetsOrOwner(tokenId)
    {
        _setPriority(tokenId, priorities);
    }

    function approveForAssets(address to, uint256 tokenId) external virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert RMRKApprovalForAssetsToCurrentOwner();

        if (
            _msgSender() != owner &&
            !_isApprovedForAllForAssets(owner, _msgSender())
        ) revert RMRKApproveForAssetsCallerIsNotOwnerNorApprovedForAll();

        _approveForAssets(to, tokenId);
    }

    function setApprovalForAllForAssets(address operator, bool approved)
        external
        virtual
    {
        address owner = _msgSender();
        if (owner == operator) revert RMRKApproveForAssetsToCaller();

        _setApprovalForAllForAssets(owner, operator, approved);
    }

    function getAssetMetadata(uint64 assetId)
        public
        view
        virtual
        returns (string memory)
    {
        return _getAssetMetadata(assetId);
    }

    function getActiveAssets(uint256 tokenId)
        public
        view
        virtual
        returns (uint64[] memory)
    {
        return _getActiveAssets(tokenId);
    }

    function getPendingAssets(uint256 tokenId)
        public
        view
        virtual
        returns (uint64[] memory)
    {
        return _getPendingAssets(tokenId);
    }

    function getActiveAssetPriorities(uint256 tokenId)
        public
        view
        virtual
        returns (uint16[] memory)
    {
        return _getActiveAssetPriorities(tokenId);
    }

    function getAssetOverwrites(uint256 tokenId, uint64 assetId)
        public
        view
        virtual
        returns (uint64)
    {
        return _getAssetOverwrites(tokenId, assetId);
    }

    function getApprovedForAssets(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        return _getApprovedForAssets(tokenId);
    }

    function isApprovedForAllForAssets(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return _isApprovedForAllForAssets(owner, operator);
    }
}
