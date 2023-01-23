// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../RMRK/internalFunctionSet/LightmMintModuleInternal.sol";
import {ILightmMintModule} from "../RMRK/interfaces/ILightmMintModule.sol";

contract LightmMintModuleImplementer is
    ILightmMintModule,
    LightmMintModuleInternal,
    ReentrancyGuard
{
    /**
     * @inheritdoc ILightmMintModule
     */
    function getMintConfig() public view returns (MintConfig memory) {
        return _getMintConfig();
    }

    /**
     * @inheritdoc ILightmMintModule
     */
    function getWhitelistMerkleProofRoot() public view returns (bytes32) {
        return _getWhitelistMerkleProofRoot();
    }

    /**
     * @inheritdoc ILightmMintModule
     */
    function setWhitelistMerkleProofRoot(bytes32 root) public onlyOwner {
        _setWhitelistMerkleProofRoot(root);
    }

    /**
     * @inheritdoc ILightmMintModule
     */
    function getMintPermissions()
        public
        view
        returns (bool allowPublicMint, bool allowWhitelistMint)
    {
        return _getMintPermissions();
    }

    /**
     * @inheritdoc ILightmMintModule
     */
    function setMintPermission(MintStage mintStage, bool allow)
        public
        onlyOwner
    {
        _setMintPermission(mintStage, allow);
    }

    /**
     * @inheritdoc ILightmMintModule
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc ILightmMintModule
     */
    function withdraw() public onlyOwner {
        _withdraw();
    }

    /**
     * @inheritdoc ILightmMintModule
     */
    function mint() public payable nonReentrant {
        _directMint(msg.sender, MintStage.publicStage);
    }

    /**
     * @inheritdoc ILightmMintModule
     */
    function mint(uint256 tokenId) public payable nonReentrant {
        _directMint(msg.sender, tokenId, MintStage.publicStage);
    }

    /**
     * @inheritdoc ILightmMintModule
     */
    function whitelistMint(address to, bytes32[] memory proof)
        public
        payable
        nonReentrant
    {
        _mintByProvidingProof(to, proof);
    }

    /**
     * @inheritdoc ILightmMintModule
     */
    function whitelistMint(
        uint256 tokenId,
        address to,
        bytes32[] memory proof
    ) public payable nonReentrant {
        _mintByProvidingProof(tokenId, to, proof);
    }
}
