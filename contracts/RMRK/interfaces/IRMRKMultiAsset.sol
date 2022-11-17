// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRMRKMultiAssetEventsAndStruct {
    /**
     * @notice Used to notify listeners that a asset object is initialized at `assetId`.
     * @param assetId ID of the asset that was initialized
     */
    event AssetSet(uint64 indexed assetId);

    /**
     * @notice Used to notify listeners that a asset object at `assetId` is added to token's pending asset
     *  array.
     * @param tokenId ID of the token that received a new pending asset
     * @param assetId ID of the asset that has been added to the token's pending assets array
     * @param overwritesId ID of the asset that would be overwritten
     */
    event AssetAddedToToken(
        uint256 indexed tokenId,
        uint64 indexed assetId,
        uint64 indexed overwritesId
    );

    /**
     * @notice Used to notify listeners that a asset object at `assetId` is accepted by the token and migrated
     *  from token's pending assets array to active assets array of the token.
     * @param tokenId ID of the token that had a new asset accepted
     * @param assetId ID of the asset that was accepted
     * @param overwritesId ID of the asset that would be overwritten
     */
    event AssetAccepted(
        uint256 indexed tokenId,
        uint64 indexed assetId,
        uint64 indexed overwritesId
    );

    /**
     * @notice Used to notify listeners that a asset object at `assetId` is rejected from token and is dropped
     *  from the pending assets array of the token.
     * @param tokenId ID of the token that had a asset rejected
     * @param assetId ID of the asset that was rejected
     */
    event AssetRejected(uint256 indexed tokenId, uint64 indexed assetId);

    /**
     * @notice Used to notify listeners that token's prioritiy array is reordered.
     * @param tokenId ID of the token that had the asset priority array updated
     */
    event AssetPrioritySet(uint256 indexed tokenId);

    /**
     * @notice Used to notify listeners that owner has granted an approval to the user to manage the assets of a
     *  given token.
     * @dev Approvals must be cleared on transfer
     * @param owner Address of the account that has granted the approval for all token's assets
     * @param approved Address of the account that has been granted approval to manage the token's assets
     * @param tokenId ID of the token on which the approval was granted
     */
    event ApprovalForAssets(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @notice Used to notify listeners that owner has granted approval to the user to manage assets of all of their
     *  tokens.
     * @param owner Address of the account that has granted the approval for all assets on all of their tokens
     * @param operator Address of the account that has been granted the approval to manage the token's assets on all of the
     *  tokens
     * @param approved Boolean value signifying whether the permission has been granted (`true`) or revoked (`false`)
     */
    event ApprovalForAllForAssets(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

interface IRMRKMultiAsset is IERC165, IRMRKMultiAssetEventsAndStruct {
    /**
     * @notice Accepts a asset which id is `assetId` in pending array of `tokenId`.
     * Migrates the asset from the token's pending asset array to the active asset array.
     *
     * Active assets cannot be removed by anyone, but can be replaced by a new asset.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * - `assetId` must exist.
     *
     * Emits an {AssetAccepted} event.
     */
    function acceptAsset(uint256 tokenId, uint64 assetId) external;

    /**
     * @notice Rejects a asset which id is `assetId` in pending array of `tokenId`.
     * Removes the asset from the token's pending asset array.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * - `assetId` must exist.
     *
     * Emits a {AssetRejected} event.
     */
    function rejectAsset(uint256 tokenId, uint64 assetId) external;

    /**
     * @notice Rejects all assets from the pending array of `tokenId`.
     * Effecitvely deletes the array.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits a {AssetRejected} event with assetId = 0.
     */
    function rejectAllAssets(uint256 tokenId) external;

    /**
     * @notice Sets a new priority array on `tokenId`.
     * The priority array is a non-sequential list of uint16s, where lowest uint64 is considered highest priority.
     * `0` priority is a special case which is equibvalent to unitialized.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * - The length of `priorities` must be equal to the length of the active assets array.
     *
     * Emits a {AssetPrioritySet} event.
     */
    function setPriority(uint256 tokenId, uint16[] calldata priorities)
        external;

    /**
     * @notice Returns IDs of active assets of `tokenId`.
     * Asset data is stored by reference, in order to access the data corresponding to the id, call `getAssetMeta(assetId)`
     */
    function getActiveAssets(uint256 tokenId)
        external
        view
        returns (uint64[] memory);

    /**
     * @notice Returns IDs of pending assets of `tokenId`.
     * Asset data is stored by reference, in order to access the data corresponding to the id, call `getAssetMeta(assetId)`
     */
    function getPendingAssets(uint256 tokenId)
        external
        view
        returns (uint64[] memory);

    /**
     * @notice Returns priorities of active assets of `tokenId`.
     */
    function getActiveAssetPriorities(uint256 tokenId)
        external
        view
        returns (uint16[] memory);

    //TODO: review definition
    /**
     * @notice Returns the asset which will be overridden if assetId is accepted from
     * a pending asset array on `tokenId`.
     * Asset data is stored by reference, in order to access the data corresponding to the id, call `getAssetMeta(assetId)`
     */
    function getAssetOverwrites(uint256 tokenId, uint64 assetId)
        external
        view
        returns (uint64);

    /**
     * @notice Returns raw bytes of `customAssetId` of `assetId`
     * Raw bytes are stored by reference in a double mapping structure of `assetId` => `customAssetId`
     *
     * Custom data is intended to be stored as generic bytes and decode by various protocols on an as-needed basis
     *
     */
    function getAssetMetadata(uint64 assetId)
        external
        view
        returns (string memory);

    /**
     * @notice Gives permission to `to` to manage `tokenId` assets.
     * This differs from transfer approvals, as approvals are not cleared when the approved
     * party accepts or rejects a asset, or sets asset priorities. This approval is cleared on token transfer.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {ApprovalForAssets} event.
     */
    function approveForAssets(address to, uint256 tokenId) external;

    /**
     * @notice Returns the account approved to manage assets of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApprovedForAssets(uint256 tokenId)
        external
        view
        returns (address);

    /**
     * @dev Approve or remove `operator` as an operator of assets for the caller.
     * Operators can call {acceptAsset}, {rejectAsset}, {rejectAllAssets} or {setPriority} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAllForAssets} event.
     */
    function setApprovalForAllForAssets(address operator, bool approved)
        external;

    /**
     * @notice Returns if the `operator` is allowed to manage all assets of `owner`.
     *
     * See {setApprovalForAllForAssets}
     */
    function isApprovedForAllForAssets(address owner, address operator)
        external
        view
        returns (bool);
}
