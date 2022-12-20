// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LightmImplStorage,ERC721Storage} from "./Storage.sol";

abstract contract LightmImplInternal {
    function getLightmImplState()
        internal
        pure
        returns (LightmImplStorage.State storage)
    {
        return LightmImplStorage.getState();
    }

    modifier onlyOwner() {
        require(
            getLightmImplState()._owner == msg.sender,
            "LightmImpl:Not Owner"
        );
        _;
    }

    function privateMintCheck() internal view {
        require(
            getLightmImplState()._owner == msg.sender,
            "LightmImpl:Not Owner"
        );
    }

    function publicMintCheck() internal view {
        LightmImplStorage.State memory s = getLightmImplState();
        ERC721Storage.State storage es = ERC721Storage.getState();
        require(s.blockMintTime < block.timestamp,"LightmImpl: Have not started");
        require(s.maxMintAmount > es._balances[msg.sender],"LightmImpl: Reach mint limit");
        require(msg.value >= s.mintPrice,"LightmImpl: Not enough money for mint");
    }
}
