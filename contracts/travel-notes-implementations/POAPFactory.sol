// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "../src/Diamond.sol";

import {POAPInit} from "./POAPInit.sol";
import {LightmCatalogImplementer} from "../implementations/LightmCatalogImplementer.sol";

import {TravelNotes} from "./TravelNotes.sol";

interface IPOAPFactory {
    struct ConstructParams {
        address diamondCutFacetAddress;
        address diamondLoupeFacetAddress;
        address nestableFacetAddress;
        address multiAssetFacetAddress;
        address equippableFacetAddress;
        address collectionMetadataFacetAddress;
        address initContractAddress;
        address implContractAddress;
        address poapMintModuleAddress;
        address travelNotesAddress;
        IDiamondCut.FacetCut[] cuts;
    }

    event POAPCreated(address instanceAddress, address deployer);

    function deployPOAP(POAPInit.InitStruct memory initStruct) external;

    function version() external pure returns (string memory);

    function cuts() external view returns (IDiamondCut.FacetCut[] memory);

    function nestableFacetAddress() external view returns (address);

    function multiAssetFacetAddress() external view returns (address);

    function equippableFacetAddress() external view returns (address);

    function collectionMetadataAddress() external view returns (address);

    function initContractAddress() external view returns (address);

    function implContractAddress() external view returns (address);

    function poapMintModuleAddress() external view returns (address);

    function travelNotesAddress() external view returns (address);
}

contract POAPFactory is IPOAPFactory {
    string private constant VERSION = "0.1.0-alpha";

    address private immutable _diamondCutFacetAddress;
    address private immutable _diamondLoupeFacetAddress;
    address private immutable _nestableFacetAddress;
    address private immutable _multiAssetFacetAddress;
    address private immutable _equippableFacetAddress;
    address private immutable _collectionMetadataFacetAddress;
    address private immutable _initContractAddress;
    address private immutable _implContractAddress;
    address private immutable _poapMintModuleAddress;

    address private immutable _travelNotesAddress;

    IDiamondCut.FacetCut[] private _cuts;

    constructor(ConstructParams memory params) {
        _diamondCutFacetAddress = params.diamondCutFacetAddress;
        _diamondLoupeFacetAddress = params.diamondLoupeFacetAddress;
        _nestableFacetAddress = params.nestableFacetAddress;
        _multiAssetFacetAddress = params.multiAssetFacetAddress;
        _equippableFacetAddress = params.equippableFacetAddress;
        _collectionMetadataFacetAddress = params.collectionMetadataFacetAddress;
        _initContractAddress = params.initContractAddress;
        _implContractAddress = params.implContractAddress;
        _poapMintModuleAddress = params.poapMintModuleAddress;

        _travelNotesAddress = params.travelNotesAddress;

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

    function poapMintModuleAddress() external view returns (address) {
        return _poapMintModuleAddress;
    }

    function travelNotesAddress() external view returns (address) {
        return _travelNotesAddress;
    }

    function deployPOAP(POAPInit.InitStruct calldata initStruct) external {
        Diamond instance = new Diamond(address(this), _diamondCutFacetAddress);

        address instanceAddress = address(instance);

        TravelNotes tn = TravelNotes(_travelNotesAddress);
        tn.setWhitelist(instanceAddress, true);

        IDiamondCut(instanceAddress).diamondCut(
            _cuts,
            _initContractAddress,
            abi.encodeWithSelector(
                POAPInit.init.selector,
                initStruct,
                msg.sender
            )
        );

        emit POAPCreated(instanceAddress, msg.sender);
    }
}
