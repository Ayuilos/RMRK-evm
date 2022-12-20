// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILightmEquippable.sol";

interface ILightmImplementer {
    function getCollectionOwner() external view returns (address owner);

    function mint(address to, uint256 tokenId) external;

    function setCollectionMetadata(string calldata newMetadata) external;

    function setFallbackURI(string calldata fallbackURI) external;

    function addBaseRelatedAssetEntry(
        uint64 id,
        ILightmEquippable.BaseRelatedData calldata baseRelatedAssetData,
        string memory metadataURI
    ) external;

    function addAssetEntry(uint64 id, string memory metadataURI) external;

    function addAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 toBeReplacedId
    ) external;
}
