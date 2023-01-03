// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import {IRMRKMultiAsset} from "./IRMRKMultiAsset.sol";

interface ILightmMultiAssetEventsAndStruct {
    struct Asset {
        uint64 id;
        string metadataURI;
    }
}

interface ILightmMultiAssetExtension is ILightmMultiAssetEventsAndStruct {
    /**
     * @notice This method is a more intuitive interface for `IRMRKMultiAsset.acceptAsset` with no `childIndex`,
     * @dev This will cost more gas, but it's more friendly to devs
     */
    function acceptAsset(uint256 tokenId, uint64 assetId) external;

    /**
     * @notice This method is a more intuitive interface for `IRMRKMultiAsset.rejectAsset` with no `childIndex`,
     * @dev This will cost more gas, but it's more friendly to devs
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

    /**
     * @notice This method not just return assetIds but also including metadataURI
     */
    function getFullAssets(uint256 tokenId)
        external
        view
        returns (Asset[] memory);

    /**
     * @notice This method not just return assetIds but also including metadataURI
     */
    function getFullPendingAssets(uint256 tokenId)
        external
        view
        returns (Asset[] memory);
}
