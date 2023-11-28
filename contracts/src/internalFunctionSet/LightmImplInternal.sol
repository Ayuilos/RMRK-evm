// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILightmImplementerEventsAndStruct} from "../interfaces/ILightmImplementer.sol";
import {LightmImplStorage, ERC721Storage} from "./Storage.sol";

abstract contract LightmImplInternal is ILightmImplementerEventsAndStruct {
    function getLightmImplState()
        internal
        pure
        returns (LightmImplStorage.State storage)
    {
        return LightmImplStorage.getState();
    }

    function _isOwner() internal view returns (bool) {
        return getLightmImplState()._owner == msg.sender;
    }

    function _setCollectionOwner(address target) internal {
        address oldOwner = getLightmImplState()._owner;
        getLightmImplState()._owner = target;

        emit OwnershipTransferred(oldOwner, target);
    }

    modifier onlyOwner() {
        require(_isOwner(), "LightmImpl:Not Owner");
        _;
    }
}
