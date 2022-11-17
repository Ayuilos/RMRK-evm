// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import {IRMRKMultiAsset} from "./IRMRKMultiAsset.sol";

interface ILightmMultiAssetEventsAndStruct {
    struct Asset {
        uint64 id;
        string metadataURI;
    }
}

interface ILightmMultiAsset is
    ILightmMultiAssetEventsAndStruct,
    IRMRKMultiAsset
{
    function getFullAssets(uint256 tokenId)
        external
        view
        returns (Asset[] memory);

    function getFullPendingAssets(uint256 tokenId)
        external
        view
        returns (Asset[] memory);
}
