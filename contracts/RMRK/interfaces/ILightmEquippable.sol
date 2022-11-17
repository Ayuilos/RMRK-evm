// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "./IRMRKNestable.sol";
import "./IRMRKMultiAsset.sol";

interface ILightmEquippableEventsAndStruct {
    event BaseRelatedAssetAdd(uint64 indexed id);

    event SlotEquipmentsAdd(
        uint256 indexed tokenId,
        uint64 indexed baseRelatedAssetId,
        SlotEquipment[] slotEquipments
    );

    event SlotEquipmentsRemove(
        uint256 indexed tokenId,
        uint64 indexed baseRelatedAssetId,
        uint64[] indexes
    );

    /**
        @dev `baseAddress` and `partIds` be used to construct a BaseStorage instance,
        `targetBaseAddress` and `targetSlotId` be used to point at a Base slot,
        the rest attributes are the same with `Asset`
     */
    struct BaseRelatedAsset {
        uint64 id;
        address baseAddress;
        uint64 targetSlotId;
        address targetBaseAddress;
        uint64[] partIds;
        string metadataURI;
    }

    struct BaseRelatedData {
        address baseAddress;
        uint64 targetSlotId;
        address targetBaseAddress;
        uint64[] partIds;
    }

    struct SlotEquipment {
        uint256 tokenId;
        uint64 baseRelatedAssetId;
        uint64 slotId;
        uint64 childBaseRelatedAssetId;
        IRMRKNestable.Child child;
    }

    struct EquipmentPointer {
        uint256 equipmentIndex;
        uint256 recordIndex;
    }
}

interface ILightmEquippable is ILightmEquippableEventsAndStruct {
    function getBaseRelatedAsset(uint64 baseRelatedAssetId)
        external
        view
        returns (BaseRelatedAsset memory baseRelatedAsset);

    function getBaseRelatedAssets(uint64[] memory)
        external
        view
        returns (BaseRelatedAsset[] memory);

    function getActiveBaseRelatedAssets(uint256 tokenId)
        external
        view
        returns (uint64[] memory);

    function getAllBaseRelatedAssetIds()
        external
        view
        returns (uint64[] memory allBaseRelatedAssetIds);

    function getSlotEquipment(
        uint256 tokenId,
        uint64 baseRelatedAssetId,
        uint64 slotId
    ) external view returns (SlotEquipment memory slotEquipment);

    function getSlotEquipment(
        address childContract,
        uint256 childTokenId,
        uint64 childBaseRelatedAssetId
    ) external view returns (SlotEquipment memory slotEquipment);

    function getSlotEquipments(uint256 tokenId, uint64 baseRelatedAsset)
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
        uint64 baseRelatedAssetId,
        SlotEquipment[] memory slotEquipments,
        bool doMoreCheck
    ) external;

    function removeSlotEquipments(
        uint256 tokenId,
        uint64 baseRelatedAssetId,
        uint64[] memory slotIds
    ) external;

    function removeSlotEquipments(
        address childContract,
        uint256 childTokenId,
        uint64[] calldata childBaseRelatedAssetIds
    ) external;
}
