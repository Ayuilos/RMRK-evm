// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import {LightmInit} from "../LightmInit.sol";
import {IDiamondCut} from "./IDiamondCut.sol";

interface ILightmUniversalFactory {
    struct ConstructParams {
        address validatorLibAddress;
        address maRenderUtilsAddress;
        address equippableRenderUtilsAddress;
        address diamondCutFacetAddress;
        address diamondLoupeFacetAddress;
        address nestableFacetAddress;
        address multiAssetFacetAddress;
        address equippableFacetAddress;
        address collectionMetadataFacetAddress;
        address initContractAddress;
        address implContractAddress;
        address mintModuleAddress;
        IDiamondCut.FacetCut[] cuts;
    }

    event LightmCollectionCreated(
        address indexed collectionAddress,
        address indexed owner
    );

    function deployCollection(LightmInit.InitStruct memory initStruct) external;

    function deployCatalog(string memory metadataURI, string memory type_)
        external;

    function version() external pure returns (string memory);

    function cuts() external view returns (IDiamondCut.FacetCut[] memory);

    function validatorLibAddress() external view returns (address);

    function maRenderUtilsAddress() external view returns (address);

    function equippableRenderUtilsAddress() external view returns (address);

    function nestableFacetAddress() external view returns (address);

    function multiAssetFacetAddress() external view returns (address);

    function equippableFacetAddress() external view returns (address);

    function collectionMetadataAddress() external view returns (address);

    function initContractAddress() external view returns (address);

    function implContractAddress() external view returns (address);

    function mintModuleAddress() external view returns (address);
}
