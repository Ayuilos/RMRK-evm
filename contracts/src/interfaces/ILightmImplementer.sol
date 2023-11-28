// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILightmEquippable.sol";

interface ILightmImplementerEventsAndStruct {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

interface ILightmImplementer is ILightmImplementerEventsAndStruct {
    function owner() external view returns (address owner);

    function transferOwnership(address target) external;

    function setCollectionMetadata(string calldata newMetadata) external;

    function setFallbackURI(string calldata fallbackURI) external;

    function addCatalogRelatedAssetEntry(
        uint64 id,
        ILightmEquippable.CatalogRelatedData calldata catalogRelatedAssetData,
        string memory metadataURI
    ) external;

    function addAssetEntry(uint64 id, string memory metadataURI) external;

    function addAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 toBeReplacedId
    ) external;
}
