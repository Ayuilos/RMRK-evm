// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LightmImplStorage} from "./Storage.sol";

abstract contract LightmImplInternal {
    function getLightmImplState()
        internal
        pure
        returns (LightmImplStorage.State storage)
    {
        return LightmImplStorage.getState();
    }

    function setMintPrice(uint256 price) internal onlyOwner {
        LightmImplStorage.getState().mintPrice = price;
    }

    function setMintTime(uint256 timestamp) internal onlyOwner {
        LightmImplStorage.getState().blockMintTime = timestamp;
    }

    modifier greaterThanValue() {
        require(
            msg.value >= getLightmImplState().mintPrice,
            "LightmImpl: value less than mint price"
        );
        _;
    }

    modifier reachedStartMintTime() {
        require(
            block.timestamp >= getLightmImplState().mintPrice,
            "LightmImpl: have not reach start time"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            getLightmImplState()._owner == msg.sender,
            "LightmImpl:Not Owner"
        );
        _;
    }
}
