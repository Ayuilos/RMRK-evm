// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import {IRMRKMultiAsset} from "./IRMRKMultiAsset.sol";

interface ILightmMultiAssetEventsAndStruct {
    struct Asset {
        uint64 id;
        string metadataURI;
    }
}

interface ILightmMultiAssetExtension is
    ILightmMultiAssetEventsAndStruct
{
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

    function getFullAssets(uint256 tokenId)
        external
        view
        returns (Asset[] memory);

    function getFullPendingAssets(uint256 tokenId)
        external
        view
        returns (Asset[] memory);
}
