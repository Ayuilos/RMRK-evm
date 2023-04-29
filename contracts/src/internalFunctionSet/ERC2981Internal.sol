// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import {ERC2981Storage} from "./Storage.sol";

abstract contract ERC2981Internal {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    function getERC2981State()
        internal
        pure
        returns (ERC2981Storage.State storage)
    {
        return ERC2981Storage.getState();
    }

    function _royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) internal view virtual returns (address, uint256) {
        ERC2981Storage.State storage s = getERC2981State();
        RoyaltyInfo memory royalty;

        royalty.receiver = s._tokenRoyaltyInfo[_tokenId].receiver;
        royalty.royaltyFraction = s._tokenRoyaltyInfo[_tokenId].royaltyFraction;

        if (royalty.receiver == address(0)) {
            royalty.receiver = s._defaultRoyaltyInfo.receiver;
            royalty.royaltyFraction = s._defaultRoyaltyInfo.royaltyFraction;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) /
            _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        ERC2981Storage.State storage s = getERC2981State();

        s._defaultRoyaltyInfo.receiver = receiver;
        s._defaultRoyaltyInfo.royaltyFraction = feeNumerator;
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete getERC2981State()._defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: Invalid parameters");

        ERC2981Storage.State storage s = getERC2981State();

        s._tokenRoyaltyInfo[tokenId].receiver = receiver;
        s._tokenRoyaltyInfo[tokenId].royaltyFraction = feeNumerator;
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete getERC2981State()._tokenRoyaltyInfo[tokenId];
    }
}
