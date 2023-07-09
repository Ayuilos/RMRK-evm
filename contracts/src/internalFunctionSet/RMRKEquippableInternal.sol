// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../interfaces/IERC6220.sol";
import {ERC6220Storage} from "./Storage.sol";
import "./LightmEquippableInternal.sol";

error RMRKEquippableEquipNotAllowedByCatalog();
error RMRKNotEquipped();
error RMRKSlotAlreadyUsed();
error RMRKTargetAssetCannotReceiveSlot();
error RMRKTokenCannotBeEquippedWithAssetIntoSlot();

contract RMRKEquippableInternal is
    IERC6220EventsAndStruct,
    LightmEquippableInternal
{
    using RMRKLib for uint64[];

    function getRMRKEquippableState()
        internal
        pure
        returns (ERC6220Storage.State storage)
    {
        return ERC6220Storage.getState();
    }

    /**
     * @notice Used to add a asset entry.
     * @dev This internal function warrants custom access control to be implemented when used.
     * @param id ID of the asset being added
     * @param equippableGroupId ID of the equippable group being marked as equippable into the slot associated with
     *  `Parts` of the `Slot` type
     * @param catalogAddress Address of the `Catalog` associated with the asset
     * @param metadataURI The metadata URI of the asset
     * @param partIds An array of IDs of fixed and slot parts to be included in the asset
     */
    function _addAssetEntry(
        uint64 id,
        uint64 equippableGroupId,
        address catalogAddress,
        string memory metadataURI,
        uint64[] memory partIds
    ) internal virtual {
        _addCatalogRelatedAssetEntry(
            id,
            CatalogRelatedData({
                catalogAddress: catalogAddress,
                targetSlotId: uint64(0),
                targetCatalogAddress: address(0),
                partIds: partIds
            }),
            metadataURI
        );
        getRMRKEquippableState()._equippableGroupIds[id] = equippableGroupId;
    }

    function _equip(IntakeEquip memory data) internal virtual {
        uint256 tokenId = data.tokenId;
        uint64 assetId = data.assetId;
        uint64 slotPartId = data.slotPartId;
        uint64 childAssetId = data.childAssetId;
        ILightmEquippable.CatalogRelatedAsset
            memory targetCRA = _getCatalogRelatedAsset(assetId);

        {
            SlotEquipment memory existSE = _getSlotEquipment(
                tokenId,
                assetId,
                slotPartId
            );

            if (existSE.child.contractAddress != address(0)) {
                revert RMRKSlotAlreadyUsed();
            }
        }

        {
            (, bool exist) = targetCRA.partIds.indexOf(slotPartId);

            if (!exist) {
                revert RMRKTargetAssetCannotReceiveSlot();
            }
        }

        IRMRKNestable.Child memory child = _childOf(tokenId, data.childIndex);

        // Check from child perspective intention to be used in part
        // We add reentrancy guard because of this call, it happens before updating state
        if (
            !IERC6220WithoutIERC5773(child.contractAddress)
                .canTokenBeEquippedWithAssetIntoSlot(
                    address(this),
                    child.tokenId,
                    data.childAssetId,
                    slotPartId
                )
        ) revert RMRKTokenCannotBeEquippedWithAssetIntoSlot();

        // Check from catalog perspective
        if (
            !IRMRKCatalog(targetCRA.catalogAddress).checkIsEquippable(
                slotPartId,
                child.contractAddress
            )
        ) revert RMRKEquippableEquipNotAllowedByCatalog();

        _beforeEquip(data);

        SlotEquipment[] memory slotEquipments = new SlotEquipment[](1);
        slotEquipments[0] = SlotEquipment({
            tokenId: tokenId,
            catalogRelatedAssetId: assetId,
            slotId: slotPartId,
            childCatalogRelatedAssetId: childAssetId,
            child: child
        });

        _addSlotEquipments(tokenId, assetId, slotEquipments, true);

        emit ChildAssetEquipped(
            tokenId,
            assetId,
            slotPartId,
            child.tokenId,
            child.contractAddress,
            childAssetId
        );

        _afterEquip(data);
    }

    /**
     * @notice Private function used to unequip child from parent token.
     * @dev Emits ***ChildAssetUnequipped*** event.
     * @param tokenId ID of the parent from which the child is being unequipped
     * @param assetId ID of the parent's asset that contains the `Slot` into which the child is equipped
     * @param slotPartId ID of the `Slot` from which to unequip the child
     */
    function _unequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) internal virtual {
        SlotEquipment memory slotEquipment = _getSlotEquipment(
            tokenId,
            assetId,
            slotPartId
        );
        IRMRKNestable.Child memory child = slotEquipment.child;

        if (child.contractAddress == address(0)) {
            revert RMRKNotEquipped();
        }

        _beforeUnequip(tokenId, assetId, slotPartId);

        uint64[] memory slotIds = new uint64[](1);
        slotIds[0] = slotPartId;
        _removeSlotEquipments(tokenId, assetId, slotIds);

        emit ChildAssetUnequipped(
            tokenId,
            assetId,
            slotPartId,
            child.tokenId,
            child.contractAddress,
            slotEquipment.childCatalogRelatedAssetId
        );

        _afterUnequip(tokenId, assetId, slotPartId);
    }

    function _isChildEquipped(
        uint256 tokenId,
        address childAddress,
        uint256 childId
    ) internal view virtual returns (bool) {
        SlotEquipment[] memory slotEquipments = _getSlotEquipments(
            childAddress,
            childId
        );
        uint256 len = slotEquipments.length;

        for (uint256 i; i < len; ) {
            SlotEquipment memory slotEquipment = slotEquipments[i];

            if (slotEquipment.tokenId == tokenId) {
                return true;
            }

            unchecked {
                ++i;
            }
        }

        return false;
    }

    // --------------------- ADMIN VALIDATION ---------------------

    /**
     * @notice Internal function used to declare that the assets belonging to a given `equippableGroupId` are
     *  equippable into the `Slot` associated with the `partId` of the collection at the specified `parentAddress`.
     * @dev Emits ***ValidParentEquippableGroupIdSet*** event.
     * @param equippableGroupId ID of the equippable group
     * @param parentAddress Address of the parent into which the equippable group can be equipped into
     * @param slotPartId ID of the `Slot` that the items belonging to the equippable group can be equipped into
     */
    function _setValidParentForEquippableGroup(
        uint64 equippableGroupId,
        address parentAddress,
        uint64 slotPartId
    ) internal virtual {
        if (equippableGroupId == uint64(0) || slotPartId == uint64(0))
            revert RMRKIdZeroForbidden();
        getRMRKEquippableState()._validParentSlots[equippableGroupId][
                parentAddress
            ] = slotPartId;
        emit ValidParentEquippableGroupIdSet(
            equippableGroupId,
            slotPartId,
            parentAddress
        );
    }

    function _canTokenBeEquippedWithAssetIntoSlot(
        address parent,
        uint256 tokenId,
        uint64 assetId,
        uint64 slotId
    ) internal view virtual returns (bool) {
        ERC6220Storage.State storage res = getRMRKEquippableState();

        uint64 equippableGroupId = res._equippableGroupIds[assetId];
        uint64 equippableSlot = res._validParentSlots[equippableGroupId][
            parent
        ];
        if (equippableSlot == slotId) {
            (, bool found) = _getActiveAssets(tokenId).indexOf(assetId);
            return found;
        }
        return false;
    }

    // --------------------- Getting Extended Assets ---------------------

    function _getAssetAndEquippableData(uint256, uint64 assetId)
        internal
        view
        virtual
        returns (
            string memory,
            uint64,
            address,
            uint64[] memory
        )
    {
        CatalogRelatedAsset memory cra = _getCatalogRelatedAsset(assetId);

        return (
            _getAssetMetadata(assetId),
            getRMRKEquippableState()._equippableGroupIds[assetId],
            cra.catalogAddress,
            cra.partIds
        );
    }

    ////////////////////////////////////////
    //              UTILS
    ////////////////////////////////////////

    function _getEquipment(
        uint256 tokenId,
        address targetCatalogAddress,
        uint64 slotPartId
    ) internal view virtual returns (Equipment memory) {
        SlotEquipment memory slotEquipment;
        uint64[] memory activeCRAIds = _getActiveCatalogRelatedAssets(tokenId);
        uint256 len = activeCRAIds.length;

        for (uint256 i; i < len; ) {
            CatalogRelatedAsset memory cra = _getCatalogRelatedAsset(
                activeCRAIds[i]
            );

            if (cra.catalogAddress == targetCatalogAddress) {
                slotEquipment = _getSlotEquipment(
                    tokenId,
                    activeCRAIds[i],
                    slotPartId
                );
                break;
            }

            unchecked {
                ++i;
            }
        }

        return
            Equipment({
                assetId: slotEquipment.catalogRelatedAssetId,
                childAssetId: slotEquipment.childCatalogRelatedAssetId,
                childId: slotEquipment.child.tokenId,
                childEquippableAddress: slotEquipment.child.contractAddress
            });
    }

    // HOOKS

    /**
     * @notice A hook to be called before a equipping a asset to the token.
     * @dev The `IntakeEquip` struct consist of the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param data The `IntakeEquip` struct containing data of the asset that is being equipped
     */
    function _beforeEquip(IntakeEquip memory data) internal virtual {}

    /**
     * @notice A hook to be called after equipping a asset to the token.
     * @dev The `IntakeEquip` struct consist of the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param data The `IntakeEquip` struct containing data of the asset that was equipped
     */
    function _afterEquip(IntakeEquip memory data) internal virtual {}

    /**
     * @notice A hook to be called before unequipping a asset from the token.
     * @param tokenId ID of the token from which the asset is being unequipped
     * @param assetId ID of the asset being unequipped
     * @param slotPartId ID of the slot from which the asset is being unequipped
     */
    function _beforeUnequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) internal virtual {}

    /**
     * @notice A hook to be called after unequipping a asset from the token.
     * @param tokenId ID of the token from which the asset was unequipped
     * @param assetId ID of the asset that was unequipped
     * @param slotPartId ID of the slot from which the asset was unequipped
     */
    function _afterUnequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) internal virtual {}
}
