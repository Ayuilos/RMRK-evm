// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CollectionMetadataStorage} from "./Storage.sol";
import "../interfaces/IRMRKCollectionMetadata.sol";

abstract contract RMRKCollectionMetadataInternal is
    IRMRKCollectionMetadataEventsAndStruct
{
    function getCollectionMetadataState()
        internal
        pure
        returns (CollectionMetadataStorage.State storage)
    {
        return CollectionMetadataStorage.getState();
    }

    function _setCollectionMetadata(string memory newMetadata) internal {
        getCollectionMetadataState()._collectionMetadata = newMetadata;

        emit RMRKCollectionMetdataSet(newMetadata);
    }
}
