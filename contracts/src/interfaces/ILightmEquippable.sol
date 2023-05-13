// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "./IRMRKNestable.sol";

interface ILightmEquippableEventsAndStruct {
    event CatalogRelatedAssetAdd(uint64 indexed id);

    event SlotEquipmentsAdd(
        uint256 indexed tokenId,
        uint64 indexed catalogRelatedAssetId,
        SlotEquipment[] slotEquipments
    );

    event SlotEquipmentsRemove(
        uint256 indexed tokenId,
        uint64 indexed catalogRelatedAssetId,
        uint64[] indexes
    );

    /**
        @dev `catalogAddress` and `partIds` be used to construct a Catalog instance,
        `targetCatalogAddress` and `targetSlotId` be used to point at a Catalog slot,
        the rest attributes are the same with `Asset`
     */
    struct CatalogRelatedAsset {
        uint64 id;
        address catalogAddress;
        uint64 targetSlotId;
        address targetCatalogAddress;
        uint64[] partIds;
        string metadataURI;
    }

    struct CatalogRelatedData {
        address catalogAddress;
        uint64 targetSlotId;
        address targetCatalogAddress;
        uint64[] partIds;
    }

    struct SlotEquipment {
        uint256 tokenId;
        uint64 catalogRelatedAssetId;
        uint64 slotId;
        uint64 childCatalogRelatedAssetId;
        IRMRKNestable.Child child;
    }

    struct EquipmentPointer {
        // We need this property to mark if current pointer is valid
        // because a valid pointer's value can also equal to default pointer's value
        bool exist;
        uint256 equipmentIndex;
        uint256 recordIndex;
    }
}

interface ILightmEquippable is ILightmEquippableEventsAndStruct {
    function getCatalogRelatedAsset(uint64 catalogRelatedAssetId)
        external
        view
        returns (CatalogRelatedAsset memory catalogRelatedAsset);

    function getCatalogRelatedAssets(uint64[] memory)
        external
        view
        returns (CatalogRelatedAsset[] memory);

    function getActiveCatalogRelatedAssets(uint256 tokenId)
        external
        view
        returns (uint64[] memory);

    function getAllCatalogRelatedAssetIds()
        external
        view
        returns (uint64[] memory allCatalogRelatedAssetIds);

    function getSlotEquipment(
        uint256 tokenId,
        uint64 catalogRelatedAssetId,
        uint64 slotId
    ) external view returns (SlotEquipment memory slotEquipment);

    function getSlotEquipment(
        address childContract,
        uint256 childTokenId,
        uint64 childCatalogRelatedAssetId
    ) external view returns (SlotEquipment memory slotEquipment);

    function getSlotEquipments(uint256 tokenId, uint64 catalogRelatedAsset)
        external
        view
        returns (SlotEquipment[] memory slotEquipments);

    function getSlotEquipments(address childContract, uint256 tokenId)
        external
        view
        returns (SlotEquipment[] memory slotEquipments);

    function getAllSlotEquipments()
        external
        view
        returns (SlotEquipment[] memory slotEquipments);

    function addSlotEquipments(
        uint256 tokenId,
        uint64 catalogRelatedAssetId,
        SlotEquipment[] memory slotEquipments,
        bool doMoreCheck
    ) external;

    function removeSlotEquipments(
        uint256 tokenId,
        uint64 catalogRelatedAssetId,
        uint64[] memory slotIds
    ) external;

    function removeSlotEquipments(
        address childContract,
        uint256 childTokenId,
        uint64[] calldata childCatalogRelatedAssetIds
    ) external;
}
