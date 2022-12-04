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

/**
 * @title RMRKMultiAssetFacet
 * @author Lightm
 * @notice Smart contract of the RMRK Multi asset module.
 * @dev This contract has been reoriganized into Diamond facet, we storage it by AppStorage
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

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
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

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return _tokenURI(tokenId);
    }

    // ------------------------ Ownership ------------------------

    function ownerOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
        return _ownerOf(tokenId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(
        address owner
    ) public view virtual override returns (uint256) {
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
    function getApproved(
        uint256 tokenId
    ) public view virtual override returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
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

    /**
     * @notice Accepts an asset at from the pending array of given token.
     * @dev Migrates the asset from the token's pending asset array to the token's active asset array.
     * @dev Active assets cannot be removed by anyone, but can be replaced by a new asset.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - `assetId` must be in pending asset array.
     * @dev Emits an {AssetAccepted} event.
     * @param tokenId ID of the token for which to accept the pending asset
     * @param assetId Index of the asset in the pending array to accept
     */
    function acceptAsset(
        uint256 tokenId,
        uint64 assetId
    ) external virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _acceptAsset(tokenId, assetId);
    }

    /**
     * @notice Rejects an asset from the pending array of given token.
     * @dev Removes the asset from the token's pending asset array.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - `assetId` must be in pending array.
     * @dev Emits a {AssetRejected} event.
     * @param tokenId ID of the token that the asset is being rejected from
     * @param assetId Id of the asset in the pending array to be rejected
     */
    function rejectAsset(
        uint256 tokenId,
        uint64 assetId
    ) external virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _rejectAsset(tokenId, assetId);
    }

    /**
     * @notice Rejects all assets from the pending array of a given token.
     * @dev Effecitvely deletes the pending array.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     * @dev Emits a {AssetRejected} event with assetId = 0.
     * @param tokenId ID of the token of which to clear the pending array.
     */
    function rejectAllAssets(
        uint256 tokenId
    ) external virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _rejectAllAssets(tokenId);
    }

    /**
     * @notice Sets a new priority array for a given token.
     * @dev The priority array is a non-sequential list of `uint16`s, where the lowest value is considered highest
     *  priority.
     * @dev Value `0` of a priority is a special case equivalent to unitialized.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - The length of `priorities` must be equal the length of the active assets array.
     * @dev Emits a {AssetPrioritySet} event.
     * @param tokenId ID of the token to set the priorities for
     * @param priorities An array of priorities of active assets. The succesion of items in the priorities array
     *  matches that of the succesion of items in the active array
     */
    function setPriority(
        uint256 tokenId,
        uint16[] memory priorities
    ) external virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _setPriority(tokenId, priorities);
    }

    /**
     * @notice Used to grant permission to the user to manage token's assets.
     * @dev This differs from transfer approvals, as approvals are not cleared when the approved party accepts or
     *  rejects an asset, or sets asset priorities. This approval is cleared on token transfer.
     * @dev Only a single account can be approved at a time, so approving the `0x0` address clears previous approvals.
     * @dev Requirements:
     *
     *  - The caller must own the token or be an approved operator.
     *  - `tokenId` must exist.
     * @dev Emits an {ApprovalForAssets} event.
     * @param to Address of the account to grant the approval to
     * @param tokenId ID of the token for which the approval to manage the assets is granted
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
     * @notice Used to add or remove an operator of assets for the caller.
     * @dev Operators can call {acceptAsset}, {rejectAsset}, {rejectAllAssets} or {setPriority} for any token
     *  owned by the caller.
     * @dev Requirements:
     *
     *  - The `operator` cannot be the caller.
     * @dev Emits an {ApprovalForAllForAssets} event.
     * @param operator Address of the account to which the operator role is granted or revoked from
     * @param approved The boolean value indicating whether the operator role is being granted (`true`) or revoked
     *  (`false`)
     */
    function setApprovalForAllForAssets(
        address operator,
        bool approved
    ) external virtual {
        address owner = _msgSender();
        if (owner == operator) revert RMRKApproveForAssetsToCaller();

        _setApprovalForAllForAssets(owner, operator, approved);
    }

    /**
     * @notice Used to fetch the asset metadata of the specified token's for given asset.
     * @dev Assets are stored by reference mapping `_assets[assetId]`.
     * @dev Can be overriden to implement enumerate, fallback or other custom logic.
     * @param assetId Asset Id, must be in the pending or active assets array
     * @return string Metadata of the asset
     */
    function getAssetMetadata(
        uint64 assetId
    ) public view virtual returns (string memory) {
        return _getAssetMetadata(assetId);
    }

    /**
     * @notice Used to retrieve the active asset IDs of a given token.
     * @dev Assets metadata is stored by reference mapping `_asset[assetId]`.
     * @param tokenId ID of the token to query
     * @return uint64[] Array of active asset IDs
     */
    function getActiveAssets(
        uint256 tokenId
    ) public view virtual returns (uint64[] memory) {
        return _getActiveAssets(tokenId);
    }

    /**
     * @notice Returns pending asset IDs for a given token
     * @dev Pending assets metadata is stored by reference mapping _pendingAsset[assetId]
     * @param tokenId the token ID to query
     * @return uint64[] pending asset IDs
     */
    function getPendingAssets(
        uint256 tokenId
    ) public view virtual returns (uint64[] memory) {
        return _getPendingAssets(tokenId);
    }

    /**
     * @notice Used to retrieve active asset priorities of a given token.
     * @dev Asset priorities are a non-sequential array of uint16 values with an array size equal to active asset
     *  priorites.
     * @param tokenId ID of the token to query
     * @return uint16[] Array of active asset priorities
     */
    function getActiveAssetPriorities(
        uint256 tokenId
    ) public view virtual returns (uint16[] memory) {
        return _getActiveAssetPriorities(tokenId);
    }

    function getAssetOverwrites(
        uint256 tokenId,
        uint64 assetId
    ) public view virtual returns (uint64) {
        return _getAssetOverwrites(tokenId, assetId);
    }

    /**
     * @notice Used to retrieve the address of the account approved to manage assets of a given token.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @param tokenId ID of the token for which to retrieve the approved address
     * @return address Address of the account that is approved to manage the specified token's assets
     */
    function getApprovedForAssets(
        uint256 tokenId
    ) public view virtual returns (address) {
        return _getApprovedForAssets(tokenId);
    }

    /**
     * @notice Used to check whether the address has been granted the operator role by a given address or not.
     * @dev See {setApprovalForAllForAssets}.
     * @param owner Address of the account that we are checking for whether it has granted the operator role
     * @param operator Address of the account that we are checking whether it has the operator role or not
     * @return bool The boolean value indicating wehter the account we are checking has been granted the operator role
     */
    function isApprovedForAllForAssets(
        address owner,
        address operator
    ) public view virtual returns (bool) {
        return _isApprovedForAllForAssets(owner, operator);
    }
}
