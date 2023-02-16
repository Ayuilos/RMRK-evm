// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LightmImplStorage, ERC721Storage} from "./Storage.sol";

abstract contract LightmImplInternal {
    function getLightmImplState()
        internal
        pure
        returns (LightmImplStorage.State storage)
    {
        return LightmImplStorage.getState();
    }

    function _isOwner() internal view returns(bool) {
        return getLightmImplState()._owner == msg.sender;
    }

    modifier onlyOwner() {
        require(
            _isOwner(),
            "LightmImpl:Not Owner"
        );
        _;
    }
}
