// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "./interfaces/ILightmEquippable.sol";
import "./internalFunctionSet/LightmEquippableInternal.sol";

contract LightmEquippableFacet is ILightmEquippable, LightmEquippableInternal {
    using RMRKLib for uint64[];

    // ------------------------ MultiAsset ------------------------

    function getCatalogRelatedAsset(uint64 catalogRelatedAssetId)
        public
        view
        returns (CatalogRelatedAsset memory catalogRelatedAsset)
    {
        catalogRelatedAsset = _getCatalogRelatedAsset(catalogRelatedAssetId);
    }

    function getCatalogRelatedAssets(uint64[] calldata catalogRelatedAssetIds)
        public
        view
        returns (CatalogRelatedAsset[] memory)
    {
        return _getCatalogRelatedAssets(catalogRelatedAssetIds);
    }

    function getActiveCatalogRelatedAssets(uint256 tokenId)
        public
        view
        returns (uint64[] memory)
    {
        return _getActiveCatalogRelatedAssets(tokenId);
    }

    function getAllCatalogRelatedAssetIds()
        public
        view
        returns (uint64[] memory allCatalogRelatedAssetIds)
    {
        allCatalogRelatedAssetIds = _getAllCatalogRelatedAssetIds();
    }

    //
    // -------------- Equipment --------------
    //

    /**
     * @dev get slotEquipment by tokenId, catalogRelatedAssetId and slotId (from parent's perspective)
     */
    function getSlotEquipment(
        uint256 tokenId,
        uint64 catalogRelatedAssetId,
        uint64 slotId
    ) public view returns (SlotEquipment memory slotEquipment) {
        slotEquipment = _getSlotEquipment(
            tokenId,
            catalogRelatedAssetId,
            slotId
        );
    }

    /**
     * @dev get slotEquipment by childContract, childTokenId and childCatalogRelatedAssetId (from child's perspective)
     */
    function getSlotEquipment(
        address childContract,
        uint256 childTokenId,
        uint64 childCatalogRelatedAssetId
    ) public view returns (SlotEquipment memory slotEquipment) {
        slotEquipment = _getSlotEquipment(
            childContract,
            childTokenId,
            childCatalogRelatedAssetId
        );
    }

    /**
     * @dev get all about one catalog instance equipment status
     */
    function getSlotEquipments(uint256 tokenId, uint64 catalogRelatedAssetId)
        public
        view
        returns (SlotEquipment[] memory)
    {
        return _getSlotEquipments(tokenId, catalogRelatedAssetId);
    }

    /**
     * @dev get one token's all catalogRelatedAssets equipment status
     */
    function getSlotEquipments(address childContract, uint256 childTokenId)
        public
        view
        returns (SlotEquipment[] memory)
    {
        return _getSlotEquipments(childContract, childTokenId);
    }

    function getAllSlotEquipments()
        public
        view
        returns (SlotEquipment[] memory slotEquipments)
    {
        slotEquipments = _getAllSlotEquipments();
    }

    function getSlotEquipmentByIndex(uint256 index)
        public
        view
        returns (SlotEquipment memory slotEquipment)
    {
        slotEquipment = _getSlotEquipmentByIndex(index);
    }

    function addSlotEquipments(
        uint256 tokenId,
        uint64 catalogRelatedAssetId,
        SlotEquipment[] memory slotEquipments,
        bool doMoreCheck
    ) public virtual {
        _addSlotEquipments(
            tokenId,
            catalogRelatedAssetId,
            slotEquipments,
            doMoreCheck
        );
    }

    function removeSlotEquipments(
        uint256 tokenId,
        uint64 catalogRelatedAssetId,
        uint64[] memory slotIds
    ) public virtual {
        _removeSlotEquipments(tokenId, catalogRelatedAssetId, slotIds);
    }

    function removeSlotEquipments(
        address childContract,
        uint256 childTokenId,
        uint64[] memory childCatalogRelatedAssetIds
    ) public virtual {
        _removeSlotEquipments(
            childContract,
            childTokenId,
            childCatalogRelatedAssetIds
        );
    }
}
