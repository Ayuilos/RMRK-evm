// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILightmMintModuleStruct {
    enum MintStyle {
        linear,
        assignable
    }

    enum MintStage {
        publicStage,
        whitelistStage
    }

    struct MintConfig {
        uint256 whitelistMintPrice;
        uint256 publicMintPrice;
        uint64 whitelistMintLimit;
        uint64 publicMintLimit;
        MintStyle mintStyle;
    }
}

interface ILightmMintModule is ILightmMintModuleStruct {
    /**
     * @dev return mint config
     * @return mintConfig {ILightmMintModuleStruct-MintConfig}
     */
    function getMintConfig() external returns (MintConfig memory mintConfig);

    /**
     * @dev get merkle proof root for whitelist mint
     */
    function getWhitelistMerkleProofRoot() external returns (bytes32 root);

    /**
     * @dev set merkle proof root for whitelist mint
     */
    function setWhitelistMerkleProofRoot(bytes32 root) external;

    /**
     * @dev get mint permissions, if public can mint or whitelist can mint
     * @return allowPublicMint if can do public mint now
     * @return allowWhitelistMint if can do whitelist mint now
     */
    function getMintPermissions()
        external
        returns (bool allowPublicMint, bool allowWhitelistMint);

    /**
     * @dev set mint permission for `publicStage` or `whitelistStage`
     */
    function setMintPermission(MintStage mintStage, bool allow) external;

    /**
     * @dev return the total supply of collection
     */
    function totalSupply() external returns (uint256 totalSupply);

    /**
     * @dev mint new token linearly
     */
    function mint() external payable;

    /**
     * @dev mint new token with specified id
     */
    function mint(uint256 tokenId) external payable;

    /**
     * @dev mint new token to `to` linearly in whitelist stage
     */
    function whitelistMint(address to, bytes32[] memory proof) external payable;

    /**
     * @dev mint new token to `to` with specified id in whitelist stage
     */
    function whitelistMint(
        uint256 tokenId,
        address to,
        bytes32[] memory proof
    ) external payable;
}
