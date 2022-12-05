// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ILightmEquippable.sol";
import "../library/ValidatorLib.sol";
import "./RMRKNestableMultiAssetInternal.sol";
import {EquippableStorage} from "./Storage.sol";

error LightmBaseRelatedAssetDidNotExist();
error LightmCurrentBaseInstanceAlreadyEquippedThisChild();
error LightmIndexOverLength();
error LightmMismatchedEquipmentAndIDLength();
error LightmMustRemoveSlotEquipmentFirst();
error LightmNotInActiveAssets();
error LightmNotValidBaseContract();
error LightmSlotEquipmentNotExist();
error LightmSlotIsOccupied();

abstract contract LightmEquippableInternal is
    ILightmEquippableEventsAndStruct,
    RMRKNestableMultiAssetInternal
{
    using RMRKLib for uint64[];
    using Address for address;

    function getEquippableState()
        internal
        pure
        returns (EquippableStorage.State storage)
    {
        return EquippableStorage.getState();
    }

    function _getBaseRelatedAsset(uint64 baseRelatedAssetId)
        internal
        view
        returns (BaseRelatedAsset memory baseRelatedAsset)
    {
        BaseRelatedData memory baseRelatedData = getEquippableState()
            ._baseRelatedDatas[baseRelatedAssetId];

        string memory assetMeta = _getAssetMetadata(baseRelatedAssetId);

        baseRelatedAsset = BaseRelatedAsset({
            id: baseRelatedAssetId,
            baseAddress: baseRelatedData.baseAddress,
            targetBaseAddress: baseRelatedData.targetBaseAddress,
            targetSlotId: baseRelatedData.targetSlotId,
            partIds: baseRelatedData.partIds,
            metadataURI: assetMeta
        });
    }

    function _getBaseRelatedAssets(uint64[] calldata baseRelatedAssetIds)
        internal
        view
        returns (BaseRelatedAsset[] memory)
    {
        uint256 len = baseRelatedAssetIds.length;
        BaseRelatedAsset[]
            memory baseRelatedAssets = new BaseRelatedAsset[](len);

        for (uint256 i; i < len; ) {
            uint64 baseRelatedAssetId = baseRelatedAssetIds[i];

            baseRelatedAssets[i] = _getBaseRelatedAsset(
                baseRelatedAssetId
            );

            unchecked {
                ++i;
            }
        }

        return baseRelatedAssets;
    }

    function _getActiveBaseRelatedAssets(uint256 tokenId)
        internal
        view
        returns (uint64[] memory)
    {
        uint64[] memory activeBaseRelatedAssetIds = getEquippableState()
            ._activeBaseRelatedAssets[tokenId];

        return activeBaseRelatedAssetIds;
    }

    function _getAllBaseRelatedAssetIds()
        internal
        view
        returns (uint64[] memory allBaseRelatedAssetIds)
    {
        allBaseRelatedAssetIds = getEquippableState()
            ._allBaseRelatedAssetIds;
    }

    //
    // -------------- Equipment --------------
    //

    /**
     * @dev get slotEquipment by tokenId, baseRelatedAssetId and slotId (from parent's perspective)
     */
    function _getSlotEquipment(
        uint256 tokenId,
        uint64 baseRelatedAssetId,
        uint64 slotId
    ) internal view returns (SlotEquipment memory slotEquipment) {
        _requireMinted(tokenId);

        EquipmentPointer storage pointer = getEquippableState()
            ._equipmentPointers[tokenId][baseRelatedAssetId][slotId];

        slotEquipment = _getSlotEquipmentByIndex(pointer.equipmentIndex);

        if (
            slotEquipment.tokenId != tokenId ||
            slotEquipment.baseRelatedAssetId != baseRelatedAssetId ||
            slotEquipment.slotId != slotId
        ) {
            revert LightmSlotEquipmentNotExist();
        }
    }

    /**
     * @dev get slotEquipment by childContract, childTokenId and childBaseRelatedAssetId (from child's perspective)
     */
    function _getSlotEquipment(
        address childContract,
        uint256 childTokenId,
        uint64 childBaseRelatedAssetId
    ) internal view returns (SlotEquipment memory slotEquipment) {
        EquipmentPointer storage pointer = getEquippableState()
            ._childEquipmentPointers[childContract][childTokenId][
                childBaseRelatedAssetId
            ];

        slotEquipment = _getSlotEquipmentByIndex(pointer.equipmentIndex);

        if (
            slotEquipment.child.contractAddress != childContract ||
            slotEquipment.child.tokenId != childTokenId ||
            slotEquipment.childBaseRelatedAssetId !=
            childBaseRelatedAssetId
        ) {
            revert LightmSlotEquipmentNotExist();
        }
    }

    /**
     * @dev get all about one base instance equipment status
     */
    function _getSlotEquipments(uint256 tokenId, uint64 baseRelatedAssetId)
        internal
        view
        returns (SlotEquipment[] memory)
    {
        _requireMinted(tokenId);

        uint64[] memory slotIds = getEquippableState()._equippedSlots[tokenId][
            baseRelatedAssetId
        ];
        uint256 len = slotIds.length;

        SlotEquipment[] memory slotEquipments = new SlotEquipment[](len);

        for (uint256 i; i < len; ) {
            slotEquipments[i] = _getSlotEquipment(
                tokenId,
                baseRelatedAssetId,
                slotIds[i]
            );

            unchecked {
                ++i;
            }
        }

        return slotEquipments;
    }

    /**
     * @dev get one token's all baseRelatedAssets equipment status
     */
    function _getSlotEquipments(address childContract, uint256 childTokenId)
        internal
        view
        returns (SlotEquipment[] memory)
    {
        uint64[] memory childBaseRelatedAssetIds = getEquippableState()
            ._equippedChildBaseRelatedAssets[childContract][childTokenId];
        uint256 len = childBaseRelatedAssetIds.length;

        SlotEquipment[] memory slotEquipments = new SlotEquipment[](len);

        for (uint256 i; i < len; ) {
            slotEquipments[i] = _getSlotEquipment(
                childContract,
                childTokenId,
                childBaseRelatedAssetIds[i]
            );

            unchecked {
                ++i;
            }
        }

        return slotEquipments;
    }

    function _getAllSlotEquipments()
        internal
        view
        returns (SlotEquipment[] memory slotEquipments)
    {
        slotEquipments = getEquippableState()._slotEquipments;
    }

    function _getSlotEquipmentByIndex(uint256 index)
        internal
        view
        returns (SlotEquipment memory slotEquipment)
    {
        if (index >= getEquippableState()._slotEquipments.length) {
            revert LightmIndexOverLength();
        }

        slotEquipment = getEquippableState()._slotEquipments[index];
    }

    /**
        @param doMoreCheck this will cost more gas but make sure data store correctly,
        if you are sure you use the correct data you could set it to `false` to reduce
        gas cost.
     */
    function _addSlotEquipments(
        uint256 tokenId,
        uint64 baseRelatedAssetId,
        SlotEquipment[] memory slotEquipments,
        bool doMoreCheck
    ) internal virtual {
        _requireMinted(tokenId);

        if (doMoreCheck) {
            uint64[] memory activeAssetIds = _getActiveAssets(tokenId);
            (, bool exist) = activeAssetIds.indexOf(baseRelatedAssetId);
            if (!exist) revert LightmNotInActiveAssets();
        }

        uint256 len = slotEquipments.length;

        for (uint256 i; i < len; ) {
            SlotEquipment memory sE = slotEquipments[i];
            EquippableStorage.State storage es = getEquippableState();

            // 1. Make sure slotEquipment is valid
            // 2. Make sure slot is not occupied
            // 3. Make sure current child has no asset participating
            //    in the equipment action of current base instance before
            if (doMoreCheck) {
                {
                    address ownAddress = address(this);
                    (bool isValid, string memory reason) = LightmValidatorLib
                        .isSlotEquipmentValid(
                            ownAddress,
                            tokenId,
                            baseRelatedAssetId,
                            sE
                        );

                    if (!isValid) {
                        revert(reason);
                    }
                }

                {
                    EquipmentPointer memory pointer = es._equipmentPointers[
                        tokenId
                    ][baseRelatedAssetId][sE.slotId];
                    SlotEquipment memory existSE = es._slotEquipments[
                        pointer.equipmentIndex
                    ];

                    if (
                        existSE.slotId != uint64(0) ||
                        existSE.childBaseRelatedAssetId != uint64(0) ||
                        existSE.child.contractAddress != address(0)
                    ) {
                        revert LightmSlotIsOccupied();
                    }
                }

                {
                    bool alreadyEquipped = es._baseAlreadyEquippedChild[
                        tokenId
                    ][baseRelatedAssetId][sE.child.contractAddress][
                            sE.child.tokenId
                        ];

                    if (alreadyEquipped) {
                        revert LightmCurrentBaseInstanceAlreadyEquippedThisChild();
                    }
                }
            }

            address childContract = sE.child.contractAddress;
            uint256 childTokenId = sE.child.tokenId;

            uint256 sELen = es._slotEquipments.length;

            uint256 equippedSlotsLen = es
            ._equippedSlots[tokenId][baseRelatedAssetId].length;

            uint256 equippedChildBRAsLen = es
            ._equippedChildBaseRelatedAssets[childContract][childTokenId]
                .length;

            // add the record to _equippedSlots
            es._equippedSlots[tokenId][baseRelatedAssetId].push(sE.slotId);

            // add the record to _baseAlreadyEquippedChild
            es._baseAlreadyEquippedChild[tokenId][baseRelatedAssetId][
                sE.child.contractAddress
            ][sE.child.tokenId] = true;

            // add the pointer which point at its position at
            // _equippedSlots(recordIndex) and _slotEquipments(equipmentIndex)
            es._equipmentPointers[tokenId][baseRelatedAssetId][
                    sE.slotId
                ] = EquipmentPointer({
                equipmentIndex: sELen,
                recordIndex: equippedSlotsLen
            });

            // add the record to _equippeeChildBaseRelatedAssets
            es
            ._equippedChildBaseRelatedAssets[childContract][childTokenId]
                .push(sE.childBaseRelatedAssetId);

            // add the pointer which point at its position at
            // _equippedChildBaseRelatedAssets(recordIndex) and _slotEquipments(equipmentIndex)
            es._childEquipmentPointers[childContract][childTokenId][
                    sE.childBaseRelatedAssetId
                ] = ILightmEquippableEventsAndStruct.EquipmentPointer({
                equipmentIndex: sELen,
                recordIndex: equippedChildBRAsLen
            });

            es._slotEquipments.push(sE);

            unchecked {
                i++;
            }
        }

        emit SlotEquipmentsAdd(tokenId, baseRelatedAssetId, slotEquipments);
    }

    function _removeSlotEquipments(
        uint256 tokenId,
        uint64 baseRelatedAssetId,
        uint64[] memory slotIds
    ) internal virtual {
        _requireMinted(tokenId);

        (, bool exist) = getEquippableState()
            ._activeBaseRelatedAssets[tokenId]
            .indexOf(baseRelatedAssetId);
        if (!exist) revert LightmNotInActiveAssets();

        uint256 len = slotIds.length;

        for (uint256 i; i < len; ) {
            uint64 slotId = slotIds[i];

            EquippableStorage.State storage es = getEquippableState();

            EquipmentPointer memory ePointer = es._equipmentPointers[tokenId][
                baseRelatedAssetId
            ][slotId];

            SlotEquipment memory slotEquipment = es._slotEquipments[
                ePointer.equipmentIndex
            ];

            // delete corresponding _baseAlreadyEquippedChild record
            delete es._baseAlreadyEquippedChild[tokenId][baseRelatedAssetId][
                slotEquipment.child.contractAddress
            ][slotEquipment.child.tokenId];

            // delete corresponding _equippedChildBaseRelatedAssets record
            {
                IRMRKNestable.Child memory child = slotEquipment.child;
                EquipmentPointer memory cEPointer = es._childEquipmentPointers[
                    child.contractAddress
                ][child.tokenId][slotEquipment.childBaseRelatedAssetId];

                uint64[] storage bRAIds = es._equippedChildBaseRelatedAssets[
                    child.contractAddress
                ][child.tokenId];

                uint64 lastBRAId = bRAIds[bRAIds.length - 1];

                bRAIds.removeItemByIndex(cEPointer.recordIndex);

                // Due to the `removeItemByIndex` code detail, has to update the lastBRA's `recordIndex`
                es
                ._childEquipmentPointers[child.contractAddress][child.tokenId][
                    lastBRAId
                ].recordIndex = cEPointer.recordIndex;
            }

            // delete corresponding _equippedSlots record
            {
                uint64[] storage equippedSlotIds = es._equippedSlots[tokenId][
                    baseRelatedAssetId
                ];

                uint64 lastSlotId = slotIds[slotIds.length - 1];

                equippedSlotIds.removeItemByIndex(ePointer.recordIndex);

                // Due to the `removeItemByIndex` code detail, has to update the lastSlot's `recordIndex`
                es
                ._equipmentPointers[tokenId][baseRelatedAssetId][lastSlotId]
                    .recordIndex = ePointer.recordIndex;
            }

            // delete corresponding _equipmentPointers record
            delete es._equipmentPointers[tokenId][baseRelatedAssetId][
                slotId
            ];

            // delete corresponding _childEquipmentPointers record
            delete es._childEquipmentPointers[
                slotEquipment.child.contractAddress
            ][slotEquipment.child.tokenId][
                    slotEquipment.childBaseRelatedAssetId
                ];

            // remove slotEquipment from _slotEquipments
            {
                SlotEquipment[] storage slotEquipments = es._slotEquipments;

                uint256 lastIndex = slotEquipments.length - 1;

                slotEquipment = slotEquipments[lastIndex];
                slotEquipments[ePointer.equipmentIndex] = slotEquipments[lastIndex];

                slotEquipments.pop();

                // Due to this remove style, the last slotEquipment's position has changed.
                // Has to update the last slotEquipment's `equipmentIndex` in corresponding pointers
                EquipmentPointer storage lastEPointer = es._equipmentPointers[
                    slotEquipment.tokenId
                ][slotEquipment.baseRelatedAssetId][slotEquipment.slotId];

                EquipmentPointer storage lastCEPointer = es
                    ._childEquipmentPointers[
                        slotEquipment.child.contractAddress
                    ][slotEquipment.child.tokenId][
                        slotEquipment.childBaseRelatedAssetId
                    ];

                uint256 equipmentIndex = ePointer.equipmentIndex;

                lastEPointer.equipmentIndex = equipmentIndex;
                lastCEPointer.equipmentIndex = equipmentIndex;
            }

            unchecked {
                ++i;
            }
        }

        emit SlotEquipmentsRemove(tokenId, baseRelatedAssetId, slotIds);
    }

    function _removeSlotEquipments(
        address childContract,
        uint256 childTokenId,
        uint64[] memory childBaseRelatedAssetIds
    ) internal virtual {
        uint256 parentTokenId;
        uint256 len = childBaseRelatedAssetIds.length;
        uint64[] memory baseRelatedAssetIds = new uint64[](len);
        uint256 pointerOfBRAIds = 0;
        uint64[][] memory slotIds = new uint64[][](len);
        uint256[] memory pointers = new uint256[](len);

        for (uint256 i; i < len; ) {
            SlotEquipment memory sE = _getSlotEquipment(
                childContract,
                childTokenId,
                childBaseRelatedAssetIds[i]
            );

            // Child only has one parent so parentTokenId is fixed in this function
            parentTokenId = sE.tokenId;

            uint64 baseRelatedAssetId = sE.baseRelatedAssetId;
            uint64 slotId = sE.slotId;

            (uint256 index, bool isExist) = baseRelatedAssetIds.indexOf(
                baseRelatedAssetId
            );
            if (isExist) {
                uint256 pointer = pointers[index];
                slotIds[index][pointer] = slotId;
                pointers[index]++;
            } else {
                baseRelatedAssetIds[pointerOfBRAIds] = baseRelatedAssetId;
                slotIds[pointerOfBRAIds][0] = slotId;

                pointers[pointerOfBRAIds] = 1;
                pointerOfBRAIds++;
            }

            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < pointerOfBRAIds; ) {
            uint64 baseRelatedAssetId = baseRelatedAssetIds[i];
            uint64[] memory slotIdsOfBRA = slotIds[i];

            _removeSlotEquipments(
                parentTokenId,
                baseRelatedAssetId,
                slotIdsOfBRA
            );

            unchecked {
                ++i;
            }
        }
    }

    // ------------------------ Nestable internal and override ------------------------

    function _childEquipmentCheck(address childContract, uint256 childTokenId)
        internal
        view
    {
        ILightmEquippable.SlotEquipment[]
            memory slotEquipments = _getSlotEquipments(
                childContract,
                childTokenId
            );

        if (slotEquipments.length > 0) {
            revert LightmMustRemoveSlotEquipmentFirst();
        }
    }

    function _unnestChild(
        uint256 tokenId,
        address to,
        address childContractAddress,
        uint256 childTokenId,
        bool isPending
    ) internal virtual override {
        _childEquipmentCheck(childContractAddress, childTokenId);

        RMRKNestableInternal._unnestChild(
            tokenId,
            to,
            childContractAddress,
            childTokenId,
            isPending
        );
    }

    // ------------------------ MultiAsset internal and override ------------------------

    function _baseRelatedAssetAccept(uint256 tokenId, uint64 assetId)
        internal
        virtual
    {
        EquippableStorage.State storage es = getEquippableState();
        // If baseRelatedDataExist, add assetId to `activeBaseAssets`
        if (_baseRelatedDataExist(es._baseRelatedDatas[assetId])) {
            MultiAssetStorage.State storage mrs = getMRState();

            uint64[] storage activeBaseRelatedAssets = es
                ._activeBaseRelatedAssets[tokenId];

            uint64 overwrites = mrs._assetOverwrites[tokenId][assetId];

            if (overwrites != uint64(0)) {
                uint256 position = es._activeBaseRelatedAssetsPosition[
                    tokenId
                ][overwrites];
                uint64 overwritesId = activeBaseRelatedAssets[position];

                if (overwritesId == overwrites) {
                    // Check if overwrites asset is participating equipment
                    // If yes, should exit equipment first.
                    (address directOwner, , ) = _directOwnerOf(tokenId);
                    if (
                        directOwner.isContract() &&
                        IERC165(directOwner).supportsInterface(
                            type(ILightmEquippable).interfaceId
                        )
                    ) {
                        try
                            ILightmEquippable(directOwner).getSlotEquipment(
                                address(this),
                                tokenId,
                                overwritesId
                            )
                        returns (ILightmEquippable.SlotEquipment memory) {
                            revert LightmMustRemoveSlotEquipmentFirst();
                        } catch {}
                    }

                    activeBaseRelatedAssets[position] = assetId;
                    es._activeBaseRelatedAssetsPosition[tokenId][
                        assetId
                    ] = position;
                } else {
                    overwrites = uint64(0);
                }
            }

            if (overwrites == uint64(0)) {
                activeBaseRelatedAssets.push(assetId);
                es._activeBaseRelatedAssetsPosition[tokenId][assetId] =
                    activeBaseRelatedAssets.length -
                    1;
            }
        }
    }

    function _acceptAssetByIndex(uint256 tokenId, uint256 index)
        internal
        virtual
        override
    {
        uint64 assetId = getMRState()._pendingAssets[tokenId][index];
        _baseRelatedAssetAccept(tokenId, assetId);

        RMRKMultiAssetInternal._acceptAssetByIndex(tokenId, index);
    }

    function _acceptAsset(uint256 tokenId, uint64 assetId)
        internal
        virtual
        override
    {
        _baseRelatedAssetAccept(tokenId, assetId);

        RMRKMultiAssetInternal._acceptAsset(tokenId, assetId);
    }

    function _addBaseRelatedAssetEntry(
        uint64 id,
        BaseRelatedData memory baseRelatedAssetData,
        string memory metadataURI
    ) internal {
        _addAssetEntry(id, metadataURI);

        getEquippableState()._baseRelatedDatas[id] = baseRelatedAssetData;
        getEquippableState()._allBaseRelatedAssetIds.push(id);

        emit BaseRelatedAssetAdd(id);
    }

    function _baseRelatedDataExist(BaseRelatedData memory baseRelatedData)
        internal
        pure
        returns (bool)
    {
        // The valid baseRelatedData at least has a valid baseAddress or a valid targetBaseAddress.
        // If both are address(0), then it does not exist.
        if (
            baseRelatedData.baseAddress != address(0) ||
            baseRelatedData.targetBaseAddress != address(0)
        ) {
            return true;
        }

        return false;
    }

    // ------------------------ Function conflicts resolve ------------------------

    function _burn(uint256 tokenId, uint256 maxChildrenBurns)
        internal
        virtual
        override
        returns (uint256)
    {
        (address immediateOwner, uint256 parentId, ) = _directOwnerOf(tokenId);
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);
        _beforeNestedTokenTransfer(
            immediateOwner,
            address(0),
            parentId,
            0,
            tokenId
        );


        {
            EquippableStorage.State storage es = getEquippableState();
            // remove all corresponding slotEquipments
            uint64[] memory baseRelatedAssetIds = es
                ._activeBaseRelatedAssets[tokenId];
            for (uint256 i; i < baseRelatedAssetIds.length; ) {
                uint64 baseRelatedAssetId = baseRelatedAssetIds[i];
                uint64[] memory slotIds = es._equippedSlots[tokenId][
                    baseRelatedAssetId
                ];

                _removeSlotEquipments(tokenId, baseRelatedAssetId, slotIds);

                unchecked {
                    ++i;
                }
            }
        }

        {
            ERC721Storage.State storage s = getState();
            s._balances[immediateOwner] -= 1;
            delete s._tokenApprovals[tokenId];
        }

        _approve(address(0), tokenId);
        _approveForAssets(address(0), tokenId);
        _cleanApprovals(tokenId);

        NestableStorage.State storage ns = getNestableState();
        Child[] memory children = ns._activeChildren[tokenId];

        delete ns._activeChildren[tokenId];
        delete ns._pendingChildren[tokenId];

        uint256 totalChildBurns;
        {
            uint256 pendingRecursiveBurns;
            uint256 length = children.length; //gas savings
            for (uint256 i; i < length; ) {
                if (totalChildBurns >= maxChildrenBurns) {
                    revert RMRKMaxRecursiveBurnsReached(
                        children[i].contractAddress,
                        children[i].tokenId
                    );
                }

                delete ns._posInChildArray[children[i].contractAddress][
                    children[i].tokenId
                ];

                unchecked {
                    // At this point we know pendingRecursiveBurns must be at least 1
                    pendingRecursiveBurns = maxChildrenBurns - totalChildBurns;
                }
                // We substract one to the next level to count for the token being burned, then add it again on returns
                // This is to allow the behavior of 0 recursive burns meaning only the current token is deleted.
                totalChildBurns +=
                    IRMRKNestable(children[i].contractAddress).burn(
                        children[i].tokenId,
                        pendingRecursiveBurns - 1
                    ) +
                    1;
                unchecked {
                    ++i;
                }
            }
        }
        // Can't remove before burning child since child will call back to get root owner
        delete ns._RMRKOwners[tokenId];

        _afterTokenTransfer(owner, address(0), tokenId);
        _afterNestedTokenTransfer(
            immediateOwner,
            address(0),
            parentId,
            0,
            tokenId
        );
        emit Transfer(owner, address(0), tokenId);
        emit NestTransfer(immediateOwner, address(0), parentId, 0, tokenId);

        return totalChildBurns;
    }
}
