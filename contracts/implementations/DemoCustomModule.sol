// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import {IAccessControl} from "../src/access/AccessControl.sol";

import "../src/internalFunctionSet/LightmEquippableInternal.sol";
import "../src/internalFunctionSet/LightmMintModuleInternal.sol";
import "../src/access/AccessControl.sol";

contract DemoCustomModule is LightmMintModuleInternal, AccessControlInternal {
    bytes32 internal constant ASSET_CONTRIBUTOR_ROLE =
        keccak256("ASSET_CONTRIBUTOR_ROLE");

    // A function that temporarily grants asset management rights to the caller
    function mintAndAddAssetToToken(
        uint64 assetId,
        uint64 toBeReplacedId
    ) external {
        uint256 totalSupplyOfTarget = _totalSupply();
        uint256 newTokenId = totalSupplyOfTarget + 1;

        _directMint(msg.sender, MintStage.publicStage);

        addAssetToTokenWithTempPermission(newTokenId, assetId, toBeReplacedId);
    }

    function addAssetToTokenWithTempPermission(
        uint256 tokenId,
        uint64 assetId,
        uint64 toBeReplacedId
    ) public {
        _grantRole(ASSET_CONTRIBUTOR_ROLE, msg.sender);

        _addAssetToToken(tokenId, assetId, toBeReplacedId);
        _acceptAsset(tokenId, assetId);

        _revokeRole(ASSET_CONTRIBUTOR_ROLE, msg.sender);
    }
}
