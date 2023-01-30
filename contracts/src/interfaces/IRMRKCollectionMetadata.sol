// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRMRKCollectionMetadataEventsAndStruct {
    /**
     * @dev notice that a new collection metadata is set
     */
    event RMRKCollectionMetdataSet(string metadataURI);
}

interface IRMRKCollectionMetadata is IERC165, IRMRKCollectionMetadataEventsAndStruct {
    function collectionMetadata() external returns (string memory);
}
