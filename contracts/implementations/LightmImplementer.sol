// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "../RMRK/library/LibDiamond.sol";
import "../RMRK/internalFunctionSet/LightmEquippableInternal.sol";
import "../RMRK/internalFunctionSet/RMRKCollectionMetadataInternal.sol";
import "../RMRK/internalFunctionSet/LightmImplInternal.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract LightmImpl is
    LightmEquippableInternal,
    RMRKCollectionMetadataInternal,
    LightmImplInternal,
    Multicall
{
    function getCollectionOwner() public view returns (address owner) {
        owner = getLightmImplState()._owner;
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
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

    function addBaseRelatedAssetEntry(
        uint64 id,
        BaseRelatedData calldata baseRelatedAssetData,
        string memory metadataURI
    ) external onlyOwner {
        _addBaseRelatedAssetEntry(id, baseRelatedAssetData, metadataURI);
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
    }
}
