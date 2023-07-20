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
        address rmrkEquippableFacetAddress;
        address collectionMetadataFacetAddress;
        address initContractAddress;
        address implContractAddress;
        address mintModuleAddress;
        IDiamondCut.FacetCut[] cuts;
    }

    struct CustomInitStruct {
        IDiamondCut.FacetCut[] cuts;
        address initAddress;
        bytes initCallData;
    }

    event LightmCollectionCreated(
        address indexed collectionAddress,
        address indexed owner,
        bytes32 salt,
        bool indexed isCustomized,
        CustomInitStruct customInitStruct
    );

    function deployCollection(
        bytes32 salt,
        LightmInit.InitStruct memory initStruct,
        CustomInitStruct memory customInitStruct
    ) external;

    function deployCatalog(
        string memory metadataURI,
        string memory type_
    ) external;

    function version() external pure returns (string memory);

    function cuts() external view returns (IDiamondCut.FacetCut[] memory);

    function validatorLibAddress() external view returns (address);

    function maRenderUtilsAddress() external view returns (address);

    function equippableRenderUtilsAddress() external view returns (address);

    function nestableFacetAddress() external view returns (address);

    function multiAssetFacetAddress() external view returns (address);

    function equippableFacetAddress() external view returns (address);

    function rmrkEquippableFacetAddress() external view returns (address);

    function collectionMetadataAddress() external view returns (address);

    function initContractAddress() external view returns (address);

    function implContractAddress() external view returns (address);

    function mintModuleAddress() external view returns (address);
}
