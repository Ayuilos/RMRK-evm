// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;
import {LightmImpl} from "./LightmImplementer.sol";
import {ERC721Storage} from "../RMRK/internalFunctionSet/Storage.sol";

contract LightmPublicMintImpl is LightmImpl {
    modifier lessThanMaxMint(address to) {
        uint256 mintAmount = ERC721Storage.getState()._balances[to];
        uint256 maxAmount = getLightmImplState().maxMintAmount;
        require(mintAmount < maxAmount, "LightmImpl: Reached max mint limit.");
        _;
    }

    function mint(
        address to,
        uint256 tokenId
    )
        public
        payable
        override
        greaterThanValue
        reachedStartMintTime
        lessThanMaxMint(to)
    {
        _safeMint(to, tokenId);
    }
}
