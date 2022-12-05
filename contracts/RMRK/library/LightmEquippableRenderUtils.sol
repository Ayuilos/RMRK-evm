// SPDX-License-Identifier: Apache-2.0

import "../interfaces/IRMRKMultiAsset.sol";
import "../interfaces/ILightmEquippable.sol";
import "./ValidatorLib.sol";

pragma solidity ^0.8.15;

/**
 * @dev Extra utility functions for composing Lightm equippable assets.
 */

library LightmEquippableRenderUtils {
    error RMRKTokenHasNoAssets();

    struct ActiveBaseRelatedAsset {
        uint64 id;
        uint16 priority;
        address baseAddress;
        uint64 targetSlotId;
        address targetBaseAddress;
        uint64[] partIds;
        string metadataURI;
    }

    struct PendingBaseRelatedAsset {
        uint64 id;
        uint64 overwritesAssetWithId;
        address baseAddress;
        uint64 targetSlotId;
        address targetBaseAddress;
        uint64[] partIds;
        string metadataURI;
    }

    struct ToBeRenderedPart {
        uint64 id;
        uint8 zIndex;
        address childAssetBaseAddress;
        string metadataURI;
    }

    function getActiveBaseRelatedAssets(address target, uint256 tokenId)
        public
        view
        returns (ActiveBaseRelatedAsset[] memory)
    {
        ILightmEquippable eTarget = ILightmEquippable(target);
        IRMRKMultiAsset maTarget = IRMRKMultiAsset(target);

        uint64[] memory assets = maTarget.getActiveAssets(tokenId);
        uint16[] memory priorities = maTarget.getActiveAssetPriorities(tokenId);
        uint256 len = assets.length;
        if (len == 0) {
            revert RMRKTokenHasNoAssets();
        }

        ActiveBaseRelatedAsset[]
            memory activeBaseRelatedAssets = new ActiveBaseRelatedAsset[](len);
        ILightmEquippable.BaseRelatedAsset memory baseRelatedAsset;
        for (uint256 i; i < len; ) {
            baseRelatedAsset = eTarget.getBaseRelatedAsset(assets[i]);
            activeBaseRelatedAssets[i] = ActiveBaseRelatedAsset({
                id: assets[i],
                priority: priorities[i],
                baseAddress: baseRelatedAsset.baseAddress,
                targetSlotId: baseRelatedAsset.targetSlotId,
                targetBaseAddress: baseRelatedAsset.targetBaseAddress,
                partIds: baseRelatedAsset.partIds,
                metadataURI: baseRelatedAsset.metadataURI
            });
            unchecked {
                ++i;
            }
        }
        return activeBaseRelatedAssets;
    }

    function getPendingBaseRelatedAssets(address target, uint256 tokenId)
        public
        view
        returns (PendingBaseRelatedAsset[] memory)
    {
        ILightmEquippable eTarget = ILightmEquippable(target);
        IRMRKMultiAsset maTarget = IRMRKMultiAsset(target);

        uint64[] memory assets = maTarget.getPendingAssets(tokenId);
        uint256 len = assets.length;
        if (len == 0) {
            revert RMRKTokenHasNoAssets();
        }

        PendingBaseRelatedAsset[]
            memory pendingBaseRelatedAssets = new PendingBaseRelatedAsset[](
                len
            );
        ILightmEquippable.BaseRelatedAsset memory baseRelatedAsset;
        uint64 overwritesAssetWithId;
        for (uint256 i; i < len; ) {
            baseRelatedAsset = eTarget.getBaseRelatedAsset(assets[i]);
            overwritesAssetWithId = maTarget.getAssetOverwrites(
                tokenId,
                assets[i]
            );
            pendingBaseRelatedAssets[i] = PendingBaseRelatedAsset({
                id: assets[i],
                overwritesAssetWithId: overwritesAssetWithId,
                baseAddress: baseRelatedAsset.baseAddress,
                targetSlotId: baseRelatedAsset.targetSlotId,
                targetBaseAddress: baseRelatedAsset.targetBaseAddress,
                partIds: baseRelatedAsset.partIds,
                metadataURI: baseRelatedAsset.metadataURI
            });
            unchecked {
                ++i;
            }
        }
        return pendingBaseRelatedAssets;
    }

    function getToBeRenderedParts(
        address targetContract,
        uint256 tokenId,
        uint64 baseRelatedAssetId
    ) public view returns (ToBeRenderedPart[] memory) {
        {
            (bool isValid, string memory reason) = LightmValidatorLib
                .isAValidEquippableContract(targetContract);

            if (!isValid) revert(reason);
        }
        {
            (bool isValid, string memory reason) = LightmValidatorLib
                .isAValidBaseInstance(
                    targetContract,
                    tokenId,
                    baseRelatedAssetId
                );

            if (!isValid) revert(reason);
        }

        ILightmEquippable.BaseRelatedAsset memory selfBRA = ILightmEquippable(
            targetContract
        ).getBaseRelatedAsset(baseRelatedAssetId);

        uint64[] memory partIds = selfBRA.partIds;

        uint256 len = partIds.length;

        ToBeRenderedPart[] memory toBeRenderedParts = new ToBeRenderedPart[](
            len
        );

        uint256 j;

        for (uint256 i; i < len; ) {
            IRMRKBaseStorage.Part memory part = IRMRKBaseStorage(
                selfBRA.baseAddress
            ).getPart(partIds[i]);

            if (part.itemType == IRMRKBaseStorage.ItemType.Slot) {
                ILightmEquippable.SlotEquipment memory equipment;
                try
                    ILightmEquippable(targetContract).getSlotEquipment(
                        tokenId,
                        baseRelatedAssetId,
                        partIds[i]
                    )
                returns (ILightmEquippable.SlotEquipment memory _equipment) {
                    equipment = _equipment;
                } catch (bytes memory) {
                    unchecked {
                        ++i;
                    }

                    continue;
                }

                {
                    (bool isValid, ) = LightmValidatorLib.isSlotEquipmentValid(
                        targetContract,
                        tokenId,
                        baseRelatedAssetId,
                        equipment
                    );

                    if (!isValid) {
                        unchecked {
                            ++i;
                        }

                        continue;
                    }
                }

                ILightmEquippable.BaseRelatedAsset
                    memory childAsset = ILightmEquippable(
                        equipment.child.contractAddress
                    ).getBaseRelatedAsset(equipment.childBaseRelatedAssetId);

                address childAssetBaseAddress = childAsset.baseAddress;
                bool childAssetIsBase = childAssetBaseAddress != address(0)
                    ? IERC165(childAssetBaseAddress).supportsInterface(
                        type(IRMRKBaseStorage).interfaceId
                    )
                    : false;

                toBeRenderedParts[j] = ToBeRenderedPart({
                    id: partIds[i],
                    childAssetBaseAddress: childAssetIsBase
                        ? childAssetBaseAddress
                        : address(0),
                    zIndex: part.z,
                    metadataURI: childAsset.metadataURI
                });
            } else if (part.itemType == IRMRKBaseStorage.ItemType.Fixed) {
                toBeRenderedParts[j] = ToBeRenderedPart({
                    id: partIds[i],
                    childAssetBaseAddress: address(0),
                    zIndex: part.z,
                    metadataURI: part.metadataURI
                });
            }

            unchecked {
                ++i;
                ++j;
            }
        }

        return toBeRenderedParts;
    }
}
