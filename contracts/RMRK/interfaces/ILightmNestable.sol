// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import {IRMRKNestable} from "./IRMRKNestable.sol";

interface ILightmNestableExtension {
    /**
     * @notice Used to make sure token with `tokenId` has a child token with `childTokenId` from contract `childContract`
     * @param tokenId the id of target token
     * @param childContract the address of target child contract
     * @param childTokenId the id of target child token
     * @return found if child token is found
     * @return isPending if child token is a pending child
     * @return index the index of child token in (pending)children list
     */
    function hasChild(
        uint256 tokenId,
        address childContract,
        uint256 childTokenId
    )
        external
        view
        returns (
            bool found,
            bool isPending,
            uint256 index
        );

    /**
     * @notice This method is suitable for cases where a child NFT still records the current token as its parent NFT,
     * but the parent NFT no longer contains the child NFT record. (It's a very rare situation, only if direct contract call)
     * @param tokenId the id of target token
     * @param childAddress the address of target token contract
     * @param childTokenId the id of target child token
     */
    function reclaimChild(
        uint256 tokenId,
        address childAddress,
        uint256 childTokenId
    ) external;

    /**
     * @notice This method is a more intuitive interface for `IRMRKNestable.transferChild` with no `childIndex`,
     * @dev This will cost more gas, but it's more friendly to devs
     */
    function transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        address childContractAddress,
        uint256 childTokenId,
        bool isPending,
        bytes memory data
    ) external;

    /**
     * @notice This method is a more intuitive interface for `IRMRKNestable.acceptChild` with no `childIndex`,
     * @dev This will cost more gas, but it's more friendly to devs
     */
    function acceptChild(
        uint256 tokenId,
        address childContractAddress,
        uint256 childTokenId
    ) external;

    /**
     * @dev This method is a shorthand of `IRMRKNestable.nestTransferFrom` with setting `from` to `msg.sender`
     */
    function nestTransfer(
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) external;
}
