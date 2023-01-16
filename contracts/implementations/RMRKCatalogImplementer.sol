// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "../RMRK/access/OwnableLock.sol";
import "../RMRK/RMRKCatalog.sol";

/**
 * @dev Contract for storing 'catalog' elements of NFTs to be accessed
 * by instances of RMRKAsset implementing contracts. This default
 * implementation includes an OwnableLock dependency, which allows
 * the deployer to freeze the state of the catalog contract.
 *
 * In addition, this implementation treats the catalog registry as an
 * append-only ledger, so
 */

contract RMRKCatalogImplementer is OwnableLock, RMRKCatalog {
    constructor(string memory metadataURI, string memory type_)
        RMRKCatalog(metadataURI, type_)
    {}

    function addPart(IntakeStruct calldata intakeStruct)
        public
        virtual
        onlyOwnerOrContributor
        notLocked
    {
        _addPart(intakeStruct);
    }

    function addPartList(IntakeStruct[] calldata intakeStructs)
        public
        virtual
        onlyOwnerOrContributor
        notLocked
    {
        _addPartList(intakeStructs);
    }

    function addEquippableAddresses(
        uint64 partId,
        address[] memory equippableAddresses
    ) public virtual onlyOwnerOrContributor {
        _addEquippableAddresses(partId, equippableAddresses);
    }

    function setEquippableAddresses(
        uint64 partId,
        address[] memory equippableAddresses
    ) public virtual onlyOwnerOrContributor {
        _setEquippableAddresses(partId, equippableAddresses);
    }

    function setEquippableToAll(uint64 partId)
        public
        virtual
        onlyOwnerOrContributor
    {
        _setEquippableToAll(partId);
    }

    function resetEquippableAddresses(uint64 partId)
        public
        virtual
        onlyOwnerOrContributor
    {
        _resetEquippableAddresses(partId);
    }
}