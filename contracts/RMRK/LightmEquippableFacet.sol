// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "./interfaces/ILightmEquippable.sol";
import "./internalFunctionSet/LightmEquippableInternal.sol";

contract LightmEquippableFacet is ILightmEquippable, LightmEquippableInternal {
    using RMRKLib for uint64[];

    // ------------------------ MultiAsset ------------------------

    function getBaseRelatedAsset(uint64 baseRelatedAssetId)
        public
        view
        returns (BaseRelatedAsset memory baseRelatedAsset)
    {
        baseRelatedAsset = _getBaseRelatedAsset(baseRelatedAssetId);
    }

    function getBaseRelatedAssets(uint64[] calldata baseRelatedAssetIds)
        public
        view
        returns (BaseRelatedAsset[] memory)
    {
        return _getBaseRelatedAssets(baseRelatedAssetIds);
    }

    function getActiveBaseRelatedAssets(uint256 tokenId)
        public
        view
        returns (uint64[] memory)
    {
        return _getActiveBaseRelatedAssets(tokenId);
    }

    function getAllBaseRelatedAssetIds()
        public
        view
        returns (uint64[] memory allBaseRelatedAssetIds)
    {
        allBaseRelatedAssetIds = _getAllBaseRelatedAssetIds();
    }

    //
    // -------------- Equipment --------------
    //

    /**
     * @dev get slotEquipment by tokenId, baseRelatedAssetId and slotId (from parent's perspective)
     */
    function getSlotEquipment(
        uint256 tokenId,
        uint64 baseRelatedAssetId,
        uint64 slotId
    ) public view returns (SlotEquipment memory slotEquipment) {
        slotEquipment = _getSlotEquipment(
            tokenId,
            baseRelatedAssetId,
            slotId
        );
    }

    /**
     * @dev get slotEquipment by childContract, childTokenId and childBaseRelatedAssetId (from child's perspective)
     */
    function getSlotEquipment(
        address childContract,
        uint256 childTokenId,
        uint64 childBaseRelatedAssetId
    ) public view returns (SlotEquipment memory slotEquipment) {
        slotEquipment = _getSlotEquipment(
            childContract,
            childTokenId,
            childBaseRelatedAssetId
        );
    }

    /**
     * @dev get all about one base instance equipment status
     */
    function getSlotEquipments(uint256 tokenId, uint64 baseRelatedAssetId)
        public
        view
        returns (SlotEquipment[] memory)
    {
        return _getSlotEquipments(tokenId, baseRelatedAssetId);
    }

    /**
     * @dev get one token's all baseRelatedAssets equipment status
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
        uint64 baseRelatedAssetId,
        SlotEquipment[] memory slotEquipments,
        bool doMoreCheck
    ) public virtual {
        _addSlotEquipments(
            tokenId,
            baseRelatedAssetId,
            slotEquipments,
            doMoreCheck
        );
    }

    function removeSlotEquipments(
        uint256 tokenId,
        uint64 baseRelatedAssetId,
        uint64[] memory slotIds
    ) public virtual {
        _removeSlotEquipments(tokenId, baseRelatedAssetId, slotIds);
    }

    function removeSlotEquipments(
        address childContract,
        uint256 childTokenId,
        uint64[] memory childBaseRelatedAssetIds
    ) public virtual {
        _removeSlotEquipments(
            childContract,
            childTokenId,
            childBaseRelatedAssetIds
        );
    }
}
