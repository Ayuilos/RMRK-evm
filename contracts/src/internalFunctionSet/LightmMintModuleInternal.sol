// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {LightmMintModuleStorage} from "./Storage.sol";
import "../interfaces/ILightmMintModule.sol";
import "./RMRKNestableInternal.sol";
import "./LightmImplInternal.sol";

abstract contract LightmMintModuleInternal is
    ILightmMintModuleStruct,
    LightmImplInternal,
    RMRKNestableInternal
{
    error LightmMintModuleNoWhitelistStageSet();
    error LightmMintModuleNoPublicStageSet();
    error LightmMintModuleWhitelistMintNotAllowed();
    error LightmMintModulePublicMintNotAllowed();
    error LightmMintModuleInsufficientValue();
    error LightmMintModuleOverMintLimit();
    error LightmMintModuleOverMaxSupply();
    error LightmMintModuleWrongMintStyle();
    error LightmMintModuleIncorrectMerkleProof();

    function getLightmMintModuleState()
        internal
        pure
        returns (LightmMintModuleStorage.State storage)
    {
        return LightmMintModuleStorage.getState();
    }

    function _getMintConfig()
        internal
        view
        returns (MintConfig memory mintConfig)
    {
        return getLightmMintModuleState().config;
    }

    function _getWhitelistMerkleProofRoot() internal view returns (bytes32) {
        return getLightmMintModuleState().whitelistMerkleProofRoot;
    }

    function _setWhitelistMerkleProofRoot(bytes32 root) internal {
        getLightmMintModuleState().whitelistMerkleProofRoot = root;
    }

    function _getMintPermissions()
        internal
        view
        returns (bool allowPublicMint, bool allowWhitelistMint)
    {
        LightmMintModuleStorage.State storage mms = getLightmMintModuleState();

        return (mms.allowPublicMint, mms.allowWhitelistMint);
    }

    function _setMintPermission(MintStage mintStage, bool allow) internal {
        LightmMintModuleStorage.State storage mms = getLightmMintModuleState();

        if (mintStage == MintStage.publicStage) {
            mms.allowPublicMint = allow;
        } else if (mintStage == MintStage.whitelistStage) {
            mms.allowWhitelistMint = allow;
        }
    }

    function _maxSupply() internal view returns (uint256) {
        return getLightmMintModuleState().config.maxSupply;
    }

    function _totalSupply() internal view returns (uint256) {
        return getLightmMintModuleState().totalSupply;
    }

    function _withdraw() internal {
        address owner = getLightmImplState()._owner;

        payable(owner).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        LightmMintModuleStorage.State storage mms = getLightmMintModuleState();

        if (from == address(0) && to != address(0)) {
            mms.totalSupply += 1;
        }

        if (to == address(0) && from != address(0)) {
            mms.totalSupply -= 1;
        }

        uint256 maxSupply = mms.config.maxSupply;

        if (maxSupply != 0 && mms.totalSupply > maxSupply) {
            revert LightmMintModuleOverMaxSupply();
        }
    }

    /**
     * @dev Determines whether the mint condition is met in following points
     * - mint style: `linear` or `assignable`
     * - mint limit
     * - mint permission
     * - mint price
     * will revert, if not satisfied
     */
    function _couldMint(
        address to,
        MintStage mintStage,
        MintStyle mintStyle
    ) private view {
        LightmMintModuleStorage.State storage mms = getLightmMintModuleState();
        MintConfig memory config = mms.config;

        // Has to match mint style
        if (mintStyle != config.mintStyle)
            revert LightmMintModuleWrongMintStyle();

        if (mintStage == MintStage.whitelistStage) {
            // Should not over whitelist mint limit
            uint64 count = mms.whitelistMintedTokenCount[to];
            if (count >= config.whitelistMintLimit) {
                revert LightmMintModuleOverMintLimit();
            }

            // Whitelist mint should be allowed
            if (!mms.allowWhitelistMint) {
                revert LightmMintModuleWhitelistMintNotAllowed();
            }

            // Should transfer sufficient value
            uint256 price = config.whitelistMintPrice;
            if (msg.value < price) {
                revert LightmMintModuleInsufficientValue();
            }
        } else if (mintStage == MintStage.publicStage) {
            // Should not over public mint limit
            uint64 count = mms.publicMintedTokenCount[to];
            if (count >= config.publicMintLimit) {
                revert LightmMintModuleOverMintLimit();
            }

            // Public mint should be allowed
            if (!mms.allowPublicMint) {
                revert LightmMintModulePublicMintNotAllowed();
            }

            // Should transfer sufficient value
            uint256 price = config.publicMintPrice;
            if (msg.value < price) {
                revert LightmMintModuleInsufficientValue();
            }
        }
    }

    /**
     * @dev Return extra value to caller
     */
    function _returnValue(address to, MintStage mintStage) private {
        MintConfig memory config = getLightmMintModuleState().config;
        uint256 toBeReturnedValue;
        if (mintStage == MintStage.publicStage) {
            toBeReturnedValue = msg.value - config.publicMintPrice;
        } else if (mintStage == MintStage.whitelistStage) {
            toBeReturnedValue = msg.value - config.whitelistMintPrice;
        }

        if (toBeReturnedValue > 0) {
            payable(to).transfer(toBeReturnedValue);
        }
    }

    function _count(address to, MintStage mintStage) private {
        LightmMintModuleStorage.State storage mms = getLightmMintModuleState();
        if (mintStage == MintStage.publicStage) {
            unchecked {
                mms.publicMintedTokenCount[to] += 1;
            }
        } else if (mintStage == MintStage.whitelistStage) {
            unchecked {
                mms.whitelistMintedTokenCount[to] += 1;
            }
        }
    }

    function _directMint(address to, MintStage mintStage) internal {
        _couldMint(to, mintStage, MintStyle.linear);

        uint256 totalSupply = _totalSupply();

        _safeMint(to, totalSupply + 1);

        _count(to, mintStage);

        _returnValue(to, mintStage);
    }

    function _directMint(
        address to,
        uint256 tokenId,
        MintStage mintStage
    ) internal {
        _couldMint(to, mintStage, MintStyle.assignable);

        _safeMint(to, tokenId);

        _count(to, mintStage);

        _returnValue(to, mintStage);
    }

    function _mintByProvidingProof(address to, bytes32[] memory proof)
        internal
    {
        bytes32 root = getLightmMintModuleState().whitelistMerkleProofRoot;
        bool eligible = MerkleProof.verify(
            proof,
            root,
            keccak256(abi.encodePacked(to))
        );

        if (eligible) {
            _directMint(to, MintStage.whitelistStage);
        } else {
            revert LightmMintModuleIncorrectMerkleProof();
        }
    }

    function _mintByProvidingProof(
        uint256 tokenId,
        address to,
        bytes32[] memory proof
    ) internal {
        bytes32 root = getLightmMintModuleState().whitelistMerkleProofRoot;
        bool eligible = MerkleProof.verify(
            proof,
            root,
            keccak256(abi.encodePacked(to))
        );

        if (eligible) {
            _directMint(to, tokenId, MintStage.whitelistStage);
        } else {
            revert LightmMintModuleIncorrectMerkleProof();
        }
    }
}
