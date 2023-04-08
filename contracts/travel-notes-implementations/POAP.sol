// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "../src/internalFunctionSet/LightmEquippableInternal.sol";
import "../src/internalFunctionSet/LightmImplInternal.sol";
import "../src/interfaces/IERC6454.sol";

library POAPStorage {
    struct State {
        uint256 totalSupply;
        // use uint256 0 / 1 instead of false / true to save gas
        mapping(uint256 => uint256) isNonTransferableMap;
    }

    bytes32 constant STORAGE_POSITION = keccak256("travel_notes_poap.storage");

    function getState() internal pure returns (State storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

contract POAP is
    ERC165,
    IERC6454,
    LightmEquippableInternal,
    LightmImplInternal
{
    error POAPCanOnlyMintOne();
    error POAPIsSoulBound();

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC6454).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getPOAPState() internal pure returns (POAPStorage.State storage) {
        return POAPStorage.getState();
    }

    function totalSupply() public view returns (uint256) {
        return getPOAPState().totalSupply;
    }

    function isNonTransferable(uint256 tokenId) public view returns (bool) {
        return getPOAPState().isNonTransferableMap[tokenId] == 1 ? true : false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        POAPStorage.State storage pps = getPOAPState();

        if (from != address(0) && to != address(0)) {
            if (isNonTransferable(tokenId)) {
                revert POAPIsSoulBound();
            }
        }

        if (from == address(0) && to != address(0)) {
            pps.totalSupply += 1;
        }

        if (to == address(0) && from != address(0)) {
            pps.totalSupply -= 1;
        }
    }

    function mint(
        address to,
        uint256 noteId,
        bool isSoulBound
    ) external onlyOwner {
        uint256 nextTokenId = totalSupply() + 1;

        if (isSoulBound) {
            getPOAPState().isNonTransferableMap[nextTokenId] = 1;
        }

        // asset id 1 - 10 for travel notes line 1 - 10 by default
        // be sure asset entries are added in before mint
        // or here will revert
        for (uint256 i = 1; i <= 10; i++) {
            _addAssetToToken(nextTokenId, uint64(i), uint64(0));
            _acceptAsset(nextTokenId, uint64(i));
        }

        _nestMint(to, nextTokenId, noteId, "");
    }

    // ------ Functions below is needed to override origin erc721 / rmrk-nestable contract functions to make soul-bound work ------

    function burn(uint256 tokenId)
        public
        virtual
        onlyApprovedOrDirectOwner(tokenId)
        returns (uint256)
    {
        return _burn(tokenId, 0);
    }

    function burn(uint256 tokenId, uint256 maxRecursiveBurns)
        public
        virtual
        onlyApprovedOrDirectOwner(tokenId)
        returns (uint256)
    {
        return _burn(tokenId, maxRecursiveBurns);
    }

    function nestTransfer(
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) public virtual {
        nestTransferFrom(_msgSender(), to, tokenId, destinationId, "");
    }

    function transfer(address to, uint256 tokenId) public virtual {
        transferFrom(_msgSender(), to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _transfer(from, to, tokenId);
    }

    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _nestTransfer(from, to, tokenId, destinationId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _safeTransfer(from, to, tokenId, data);
    }
}
