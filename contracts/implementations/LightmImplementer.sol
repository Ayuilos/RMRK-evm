// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "../RMRK/library/LibDiamond.sol";
import "../RMRK/internalFunctionSet/LightmEquippableInternal.sol";
import "../RMRK/internalFunctionSet/RMRKCollectionMetadataInternal.sol";
import "../RMRK/internalFunctionSet/LightmImplInternal.sol";
import {ILightmImplementer} from "../RMRK/interfaces/ILightmImplementer.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract LightmImpl is
    ILightmImplementer,
    LightmEquippableInternal,
    RMRKCollectionMetadataInternal,
    LightmImplInternal,
    Multicall
{
    function getCollectionOwner() public view returns (address owner) {
        owner = getLightmImplState()._owner;
    }

    function setCollectionMetadata(string calldata newMetadata)
        external
        onlyOwner
    {
        _setCollectionMetadata(newMetadata);
    }

    function setFallbackURI(string calldata fallbackURI) external onlyOwner {
        _setFallbackURI(fallbackURI);
    }

    function addCatalogRelatedAssetEntry(
        uint64 id,
        CatalogRelatedData calldata catalogRelatedAssetData,
        string memory metadataURI
    ) external onlyOwner {
        _addCatalogRelatedAssetEntry(id, catalogRelatedAssetData, metadataURI);
    }

    function addAssetEntry(uint64 id, string memory metadataURI)
        external
        onlyOwner
    {
        _addAssetEntry(id, metadataURI);
    }

    function addAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 toBeReplacedId
    ) external onlyApprovedForAssetsOrOwner(tokenId) {
        _addAssetToToken(tokenId, assetId, toBeReplacedId);

        // Auto accept asset if invoker is owner of token
        if (msg.sender == _ownerOf(tokenId)) {
            _acceptAsset(tokenId, assetId);
        }
    }
}
