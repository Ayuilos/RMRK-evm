// SPDX-License-Identifier: Apache-2.0

import "../interfaces/IRMRKMultiAsset.sol";

pragma solidity ^0.8.15;

/**
 * @dev Extra utility functions for composing RMRK assets.
 */

library RMRKMultiAssetRenderUtils {
    error RMRKTokenHasNoAssets();
    uint16 private constant _LOWEST_POSSIBLE_PRIORITY = type(uint16).max;

    struct ActiveAsset {
        uint64 id;
        uint16 priority;
        string metadataURI;
    }

    struct PendingAsset {
        uint64 id;
        uint64 toBeReplacedId;
        string metadataURI;
    }

    function getActiveAssets(address target, uint256 tokenId)
        public
        view
        returns (ActiveAsset[] memory)
    {
        IRMRKMultiAsset target_ = IRMRKMultiAsset(target);

        uint64[] memory assets = target_.getActiveAssets(tokenId);
        uint16[] memory priorities = target_.getActiveAssetPriorities(
            tokenId
        );
        uint256 len = assets.length;
        if (len == 0) {
            revert RMRKTokenHasNoAssets();
        }

        ActiveAsset[] memory activeAssets = new ActiveAsset[](len);
        string memory metadata;
        for (uint256 i; i < len; ) {
            metadata = target_.getAssetMetadata(tokenId, assets[i]);
            activeAssets[i] = ActiveAsset({
                id: assets[i],
                priority: priorities[i],
                metadataURI: metadata
            });
            unchecked {
                ++i;
            }
        }
        return activeAssets;
    }

    function getPendingAssets(address target, uint256 tokenId)
        public
        view
        returns (PendingAsset[] memory)
    {
        IRMRKMultiAsset target_ = IRMRKMultiAsset(target);

        uint64[] memory assets = target_.getPendingAssets(tokenId);
        uint256 len = assets.length;
        if (len == 0) {
            revert RMRKTokenHasNoAssets();
        }

        PendingAsset[] memory pendingAssets = new PendingAsset[](len);
        string memory metadata;
        uint64 toBeReplacedId;
        for (uint256 i; i < len; ) {
            metadata = target_.getAssetMetadata(tokenId, assets[i]);
            toBeReplacedId = target_.getAssetReplacements(
                tokenId,
                assets[i]
            );
            pendingAssets[i] = PendingAsset({
                id: assets[i],
                toBeReplacedId: toBeReplacedId,
                metadataURI: metadata
            });
            unchecked {
                ++i;
            }
        }
        return pendingAssets;
    }

    /**
     * @notice Returns asset metadata strings for the given ids
     *
     * Requirements:
     *
     * - `assetIds` must exist.
     */
    function getAssetsById(
        address target,
        uint256 tokenId,
        uint64[] calldata assetIds
    ) public view returns (string[] memory) {
        IRMRKMultiAsset target_ = IRMRKMultiAsset(target);
        uint256 len = assetIds.length;
        string[] memory assets = new string[](len);
        for (uint256 i; i < len; ) {
            assets[i] = target_.getAssetMetadata(tokenId, assetIds[i]);
            unchecked {
                ++i;
            }
        }
        return assets;
    }

    /**
     * @notice Returns the asset metadata with the highest priority for the given token
     */
    function getTopAssetMetaForToken(address target, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        IRMRKMultiAsset target_ = IRMRKMultiAsset(target);
        uint16[] memory priorities = target_.getActiveAssetPriorities(
            tokenId
        );
        uint64[] memory assets = target_.getActiveAssets(tokenId);
        uint256 len = priorities.length;
        if (len == 0) {
            revert RMRKTokenHasNoAssets();
        }

        uint16 maxPriority = _LOWEST_POSSIBLE_PRIORITY;
        uint64 maxPriorityAsset;
        for (uint64 i; i < len; ) {
            uint16 currentPrio = priorities[i];
            if (currentPrio < maxPriority) {
                maxPriority = currentPrio;
                maxPriorityAsset = assets[i];
            }
            unchecked {
                ++i;
            }
        }
        return target_.getAssetMetadata(tokenId, maxPriorityAsset);
    }
}
