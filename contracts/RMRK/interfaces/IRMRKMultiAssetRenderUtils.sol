// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IRMRKMultiAsset.sol";

interface IRMRKMultiAssetRenderUtils is IERC165 {
    /**
     * @notice Returns asset meta at `index` of active asset array on `tokenId`
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - `index` must be inside the range of active asset array
     */
    function getAssetByIndex(
        address target,
        uint256 tokenId,
        uint256 index
    ) external view returns (string memory);

    /**
     * @notice Returns asset meta at `index` of pending asset array on `tokenId`
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - `index` must be inside the range of pending asset array
     */
    function getPendingAssetByIndex(
        address target,
        uint256 tokenId,
        uint256 index
    ) external view returns (string memory);

    /**
     * @notice Returns asset meta strings for the given ids
     *
     * Requirements:
     *
     * - `assetIds` must exist.
     */
    function getAssetsById(address target, uint64[] calldata assetIds)
        external
        view
        returns (string[] memory);

    /**
     * @notice Returns the asset meta with the highest priority for the given token
     */
    function getTopAssetMetaForToken(address target, uint256 tokenId)
        external
        view
        returns (string memory);
}
