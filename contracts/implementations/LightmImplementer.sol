// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "../src/library/LibDiamond.sol";
import "../src/internalFunctionSet/LightmEquippableInternal.sol";
import "../src/internalFunctionSet/RMRKCollectionMetadataInternal.sol";
import "../src/internalFunctionSet/LightmImplInternal.sol";
import "../src/access/AccessControl.sol";
import {ILightmImplementer} from "../src/interfaces/ILightmImplementer.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract LightmImpl is
    ILightmImplementer,
    AccessControl,
    LightmEquippableInternal,
    RMRKCollectionMetadataInternal,
    LightmImplInternal,
    Multicall
{
    error LightmImplNotOwnerOrAssetContributor();

    bytes32 public constant ASSET_CONTRIBUTOR_ROLE =
        keccak256("ASSET_CONTRIBUTOR_ROLE");

    function _onlyOwnerOrAssetContributor() internal view {
        if (!_isOwner() && !_hasRole(ASSET_CONTRIBUTOR_ROLE, msg.sender)) {
            revert LightmImplNotOwnerOrAssetContributor();
        }
    }

    modifier onlyOwnerOrAssetContributor() {
        _onlyOwnerOrAssetContributor();
        _;
    }

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
    ) external onlyOwnerOrAssetContributor {
        _addCatalogRelatedAssetEntry(id, catalogRelatedAssetData, metadataURI);
    }

    function addAssetEntry(uint64 id, string memory metadataURI)
        external
        onlyOwnerOrAssetContributor
    {
        _addAssetEntry(id, metadataURI);
    }

    function addAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 toBeReplacedId
    ) external onlyOwnerOrAssetContributor {
        _addAssetToToken(tokenId, assetId, toBeReplacedId);

        // Auto accept asset if invoker is owner of token
        if (msg.sender == _ownerOf(tokenId)) {
            _acceptAsset(tokenId, assetId);
        }
    }
}
