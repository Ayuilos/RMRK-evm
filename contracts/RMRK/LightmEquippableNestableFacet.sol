// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import {ILightmNestableExtension} from "./interfaces/ILightmNestable.sol";
import "./RMRKNestableFacet.sol";
import "./internalFunctionSet/LightmEquippableInternal.sol";

contract LightmEquippableNestableFacet is
    ILightmNestableExtension,
    RMRKNestableFacet,
    LightmEquippableInternal
{
    constructor(
        string memory name_,
        string memory symbol_
    ) RMRKNestableFacet(name_, symbol_) {}

    // No need to override `supportsInterface` here,
    // this contract is only used to be cut by Diamond
    // and Diamond loupe facet is responsible for IERC165

    function hasChild(
        uint256 tokenId,
        address childContract,
        uint256 childTokenId
    ) public view returns (bool found, bool isPending, uint256 index) {
        return _hasChild(tokenId, childContract, childTokenId);
    }

    function reclaimChild(
        uint256 tokenId,
        address childAddress,
        uint256 childTokenId
    ) public onlyApprovedOrOwner(tokenId) {
        (address owner, uint256 ownerTokenId, bool isNft) = IRMRKNestable(
            childAddress
        ).directOwnerOf(childTokenId);

        (bool inChildrenOrPending, , ) = _hasChild(
            tokenId,
            childAddress,
            childTokenId
        );

        if (
            owner != address(this) ||
            ownerTokenId != tokenId ||
            !isNft ||
            inChildrenOrPending
        ) revert RMRKInvalidChildReclaim();

        IERC721(childAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            childTokenId
        );
    }

    function nestTransfer(
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) public virtual {
        nestTransferFrom(_msgSender(), to, tokenId, destinationId, "");
    }

    function acceptChild(
        uint256 tokenId,
        address childContractAddress,
        uint256 childTokenId
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _acceptChild(tokenId, childContractAddress, childTokenId);
    }

    function transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        address childContractAddress,
        uint256 childTokenId,
        bool isPending,
        bytes memory data
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _transferChild(
            tokenId,
            to,
            destinationId,
            childContractAddress,
            childTokenId,
            isPending,
            data
        );
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Internal, RMRKNestableMultiAssetInternal) {
        RMRKNestableMultiAssetInternal._burn(tokenId);
    }

    function _burn(
        uint256 tokenId,
        uint256 maxChildrenBurns
    )
        internal
        override(RMRKNestableInternal, LightmEquippableInternal)
        returns (uint256)
    {
        return LightmEquippableInternal._burn(tokenId, maxChildrenBurns);
    }

    function _exists(
        uint256 tokenId
    )
        internal
        view
        override(RMRKNestableInternal, RMRKNestableMultiAssetInternal)
        returns (bool)
    {
        return RMRKNestableMultiAssetInternal._exists(tokenId);
    }

    function _mint(
        address to,
        uint256 tokenId
    ) internal override(RMRKNestableInternal, RMRKNestableMultiAssetInternal) {
        RMRKNestableMultiAssetInternal._mint(to, tokenId);
    }

    function _ownerOf(
        uint256 tokenId
    )
        internal
        view
        override(RMRKNestableInternal, RMRKNestableMultiAssetInternal)
        returns (address)
    {
        return RMRKNestableMultiAssetInternal._ownerOf(tokenId);
    }

    function _tokenURI(
        uint256 tokenId
    )
        internal
        view
        override(ERC721Internal, RMRKNestableMultiAssetInternal)
        returns (string memory)
    {
        return RMRKNestableMultiAssetInternal._tokenURI(tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(RMRKNestableInternal, RMRKNestableMultiAssetInternal) {
        RMRKNestableMultiAssetInternal._transfer(from, to, tokenId);
    }

    function _transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        address childContractAddress,
        uint256 childTokenId,
        bool isPending,
        bytes memory data
    ) internal override(RMRKNestableInternal, LightmEquippableInternal) {
        LightmEquippableInternal._transferChild(
            tokenId,
            to,
            destinationId,
            childContractAddress,
            childTokenId,
            isPending,
            data
        );
    }
}
