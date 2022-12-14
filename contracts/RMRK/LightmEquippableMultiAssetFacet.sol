// SPDX-License-Identifier: Apache-2.0

// RMRKMR facet style which could be used alone

pragma solidity ^0.8.15;

import {ILightmMultiAssetExtension} from "./interfaces/ILightmMultiAsset.sol";
import "./RMRKMultiAssetFacet.sol";
import "./internalFunctionSet/LightmEquippableInternal.sol";

// !!!
// Before use, make sure you know the description below
// !!!
/**
    @dev NOTE that MultiAsset take NFT as a real unique item on-chain,
    so if you `burn` a NFT, it means that you NEVER wanna `mint` it again,
    if you do so, you are trying to raising the soul of a dead man
    (the `activeAssets` etc. of this burned token will not be removed when `burn`),
    instead of creating a new life by using a empty shell.
    You are responsible for any unknown consequences of this action, so take care of
    `mint` logic in your own implementer.
 */

contract LightmEquippableMultiAssetFacet is
    ILightmMultiAssetExtension,
    LightmEquippableInternal,
    RMRKMultiAssetFacet
{
    constructor(string memory name_, string memory symbol_)
        RMRKMultiAssetFacet(name_, symbol_)
    {}

    // No need to override `supportsInterface` here,
    // this contract is only used to be cut by Diamond
    // and Diamond loupe facet is responsible for IERC165

    function acceptAsset(uint256 tokenId, uint64 assetId)
        external
        virtual
        onlyApprovedForAssetsOrOwner(tokenId)
    {
        _acceptAsset(tokenId, assetId);
    }

    function rejectAsset(uint256 tokenId, uint64 assetId)
        external
        virtual
        onlyApprovedForAssetsOrOwner(tokenId)
    {
        _rejectAsset(tokenId, assetId);
    }

    function getAssetMetadata(uint64 assetId)
        public
        view
        virtual
        returns (string memory)
    {
        return _getAssetMetadata(assetId);
    }

    function getFullAssets(uint256 tokenId)
        external
        view
        virtual
        returns (Asset[] memory)
    {
        return _getFullAssets(tokenId);
    }

    function getFullPendingAssets(uint256 tokenId)
        external
        view
        virtual
        returns (Asset[] memory)
    {
        return _getFullPendingAssets(tokenId);
    }

    function _acceptAssetByIndex(uint256 tokenId, uint256 index)
        internal
        override(RMRKMultiAssetInternal, LightmEquippableInternal)
    {
        LightmEquippableInternal._acceptAssetByIndex(tokenId, index);
    }

    function _acceptAsset(uint256 tokenId, uint64 assetId)
        internal
        override(RMRKMultiAssetInternal, LightmEquippableInternal)
    {
        LightmEquippableInternal._acceptAsset(tokenId, assetId);
    }

    function _burn(uint256 tokenId)
        internal
        override(RMRKMultiAssetInternal, RMRKNestableMultiAssetInternal)
    {
        RMRKNestableMultiAssetInternal._burn(tokenId);
    }

    function _exists(uint256 tokenId)
        internal
        view
        override(ERC721Internal, RMRKNestableMultiAssetInternal)
        returns (bool)
    {
        return RMRKNestableMultiAssetInternal._exists(tokenId);
    }

    function _mint(address to, uint256 tokenId)
        internal
        override(ERC721Internal, RMRKNestableMultiAssetInternal)
    {
        RMRKNestableMultiAssetInternal._mint(to, tokenId);
    }

    function _ownerOf(uint256 tokenId)
        internal
        view
        override(ERC721Internal, RMRKNestableMultiAssetInternal)
        returns (address)
    {
        return RMRKNestableMultiAssetInternal._ownerOf(tokenId);
    }

    function _tokenURI(uint256 tokenId)
        internal
        view
        override(RMRKMultiAssetInternal, RMRKNestableMultiAssetInternal)
        returns (string memory)
    {
        return RMRKNestableMultiAssetInternal._tokenURI(tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Internal, RMRKNestableMultiAssetInternal) {
        RMRKNestableMultiAssetInternal._transfer(from, to, tokenId);
    }
}
