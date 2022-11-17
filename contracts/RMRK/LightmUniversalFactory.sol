// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "./Diamond.sol";
import "./DiamondCutFacet.sol";
import "./DiamondLoupeFacet.sol";
import "./LightmEquippableNestableFacet.sol";
import "./LightmEquippableMultiAssetFacet.sol";
import "./LightmEquippableFacet.sol";
import "./RMRKCollectionMetadataFacet.sol";
import "./library/ValidatorLib.sol";
import "./library/RMRKMultiAssetRenderUtils.sol";

import {LightmInit} from "./LightmInit.sol";
import {LightmImpl} from "../implementations/LightmImplementer.sol";

import "./interfaces/ILightmUniversalFactory.sol";

import "hardhat/console.sol";

contract LightmUniversalFactory is ILightmUniversalFactory {
    string private constant VERSION = "0.1.0-alpha";

    address private immutable _validatorLibAddress;
    address private immutable _maRenderUtilsAddress;
    address private immutable _diamondCutFacetAddress;
    address private immutable _diamondLoupeFacetAddress;
    address private immutable _nestableFacetAddress;
    address private immutable _multiAssetFacetAddress;
    address private immutable _equippableFacetAddress;
    address private immutable _collectionMetadataFacetAddress;
    address private immutable _initContractAddress;
    address private immutable _implContractAddress;

    IDiamondCut.FacetCut[] private _cuts;

    constructor(ConstructParams memory params) {
        _validatorLibAddress = params.validatorLibAddress;
        _maRenderUtilsAddress = params.maRenderUtilsAddress;
        _diamondCutFacetAddress = params.diamondCutFacetAddress;
        _diamondLoupeFacetAddress = params.diamondLoupeFacetAddress;
        _nestableFacetAddress = params.nestableFacetAddress;
        _multiAssetFacetAddress = params.multiAssetFacetAddress;
        _equippableFacetAddress = params.equippableFacetAddress;
        _collectionMetadataFacetAddress = params.collectionMetadataFacetAddress;
        _initContractAddress = params.initContractAddress;
        _implContractAddress = params.implContractAddress;

        IDiamondCut.FacetCut[] memory facetCuts = params.cuts;
        for (uint256 i; i < facetCuts.length; ) {
            _cuts.push(facetCuts[i]);

            // gas saving
            unchecked {
                i++;
            }
        }
    }

    function version() external pure returns (string memory) {
        return VERSION;
    }

    function cuts() external view returns (IDiamondCut.FacetCut[] memory) {
        return _cuts;
    }

    function validatorLibAddress() external view returns (address) {
        return _validatorLibAddress;
    }

    function maRenderUtilsAddress() external view returns (address) {
        return _maRenderUtilsAddress;
    }

    function nestableFacetAddress() external view returns (address) {
        return _nestableFacetAddress;
    }

    function multiAssetFacetAddress() external view returns (address) {
        return _multiAssetFacetAddress;
    }

    function equippableFacetAddress() external view returns (address) {
        return _equippableFacetAddress;
    }

    function collectionMetadataAddress() external view returns (address) {
        return _collectionMetadataFacetAddress;
    }

    function initContractAddress() external view returns (address) {
        return _initContractAddress;
    }

    function implContractAddress() external view returns (address) {
        return _implContractAddress;
    }

    function deployCollection(LightmInit.InitStruct calldata initStruct)
        external
    {
        Diamond instance = new Diamond(address(this), _diamondCutFacetAddress);

        address instanceAddress = address(instance);

        IDiamondCut(instanceAddress).diamondCut(
            _cuts,
            _initContractAddress,
            abi.encodeWithSelector(
                LightmInit.init.selector,
                initStruct,
                msg.sender
            )
        );

        emit LightmCollectionCreated(instanceAddress);
    }
}
