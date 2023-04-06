// SPDX-License-Identifier: MIT

/// @title EIP-6454 Minimalistic Non-Transferable interface for NFTs
/// @dev See https://eips.ethereum.org/EIPS/eip-6454
/// @dev Note: the ERC-165 identifier for this interface is 0xa7331ab1.

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC6454 is IERC165 {
    /**
     * @notice Used to check whether the given token is non-transferable or not.
     * @dev If this function returns `true`, the transfer of the token MUST revert execution
     * @dev If the tokenId does not exist, this method MUST revert execution
     * @param tokenId ID of the token being checked
     * @return Boolean value indicating whether the given token is non-transferable
     */
    function isNonTransferable(uint256 tokenId) external view returns (bool);
}
