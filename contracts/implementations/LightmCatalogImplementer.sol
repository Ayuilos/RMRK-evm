// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "../RMRK/access/OwnableLock.sol";
import "../RMRK/RMRKCatalog.sol";
import "../RMRK/interfaces/ILightmCatalog.sol";

/**
 * @title LightmCatalogImplementer
 * @notice Implementation of RMRK catalog with events to record `metadataURI` and `type_` changes.
 * @dev Contract for storing 'catalog' elements of NFTs to be accessed by instances of `LightmEquippable` implementing contracts.
 *  This default implementation includes an OwnableLock dependency, which allows the deployer to freeze the state of the
 *  catalog contract.
 */
contract LightmCatalogImplementer is
    ILightmCatalogEventsAndStruct,
    OwnableLock,
    RMRKCatalog
{
    constructor(string memory metadataURI, string memory type_)
        RMRKCatalog(metadataURI, type_)
    {
        emit LightmCatalogMetadataURISet(metadataURI);
        emit LightmCatalogTypeSet(type_);
    }

    function setMetadataURI(string memory metadataURI)
        public
        virtual
        onlyOwnerOrContributor
    {
        _setMetadataURI(metadataURI);

        emit LightmCatalogMetadataURISet(metadataURI);
    }

    function setType(string memory type_)
        public
        virtual
        onlyOwnerOrContributor
    {
        _setType(type_);

        emit LightmCatalogTypeSet(type_);
    }

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
