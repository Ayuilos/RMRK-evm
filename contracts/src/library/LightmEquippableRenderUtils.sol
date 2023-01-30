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

    struct ActiveCatalogRelatedAsset {
        uint64 id;
        uint16 priority;
        address catalogAddress;
        uint64 targetSlotId;
        address targetCatalogAddress;
        uint64[] partIds;
        string metadataURI;
    }

    struct PendingCatalogRelatedAsset {
        uint64 id;
        uint64 toBeReplacedId;
        address catalogAddress;
        uint64 targetSlotId;
        address targetCatalogAddress;
        uint64[] partIds;
        string metadataURI;
    }

    struct Origin {
        address contractAddress;
        uint256 tokenId;
        uint64 assetId;
    }

    struct ToBeRenderedPart {
        uint64 id;
        uint8 zIndex;
        address childAssetCatalogAddress;
        string metadataURI;
        Origin origin;
    }

    function getActiveCatalogRelatedAssets(address target, uint256 tokenId)
        public
        view
        returns (ActiveCatalogRelatedAsset[] memory)
    {
        ILightmEquippable eTarget = ILightmEquippable(target);
        IRMRKMultiAsset maTarget = IRMRKMultiAsset(target);

        uint64[] memory assets = maTarget.getActiveAssets(tokenId);
        uint16[] memory priorities = maTarget.getActiveAssetPriorities(tokenId);
        uint256 len = assets.length;
        if (len == 0) {
            revert RMRKTokenHasNoAssets();
        }

        ActiveCatalogRelatedAsset[]
            memory activeCatalogRelatedAssets = new ActiveCatalogRelatedAsset[](len);
        ILightmEquippable.CatalogRelatedAsset memory catalogRelatedAsset;
        for (uint256 i; i < len; ) {
            catalogRelatedAsset = eTarget.getCatalogRelatedAsset(assets[i]);
            activeCatalogRelatedAssets[i] = ActiveCatalogRelatedAsset({
                id: assets[i],
                priority: priorities[i],
                catalogAddress: catalogRelatedAsset.catalogAddress,
                targetSlotId: catalogRelatedAsset.targetSlotId,
                targetCatalogAddress: catalogRelatedAsset.targetCatalogAddress,
                partIds: catalogRelatedAsset.partIds,
                metadataURI: catalogRelatedAsset.metadataURI
            });
            unchecked {
                ++i;
            }
        }
        return activeCatalogRelatedAssets;
    }

    function getPendingCatalogRelatedAssets(address target, uint256 tokenId)
        public
        view
        returns (PendingCatalogRelatedAsset[] memory)
    {
        ILightmEquippable eTarget = ILightmEquippable(target);
        IRMRKMultiAsset maTarget = IRMRKMultiAsset(target);

        uint64[] memory assets = maTarget.getPendingAssets(tokenId);
        uint256 len = assets.length;
        if (len == 0) {
            revert RMRKTokenHasNoAssets();
        }

        PendingCatalogRelatedAsset[]
            memory pendingCatalogRelatedAssets = new PendingCatalogRelatedAsset[](
                len
            );
        ILightmEquippable.CatalogRelatedAsset memory catalogRelatedAsset;
        uint64 toBeReplacedId;
        for (uint256 i; i < len; ) {
            catalogRelatedAsset = eTarget.getCatalogRelatedAsset(assets[i]);
            toBeReplacedId = maTarget.getAssetReplacements(tokenId, assets[i]);
            pendingCatalogRelatedAssets[i] = PendingCatalogRelatedAsset({
                id: assets[i],
                toBeReplacedId: toBeReplacedId,
                catalogAddress: catalogRelatedAsset.catalogAddress,
                targetSlotId: catalogRelatedAsset.targetSlotId,
                targetCatalogAddress: catalogRelatedAsset.targetCatalogAddress,
                partIds: catalogRelatedAsset.partIds,
                metadataURI: catalogRelatedAsset.metadataURI
            });
            unchecked {
                ++i;
            }
        }
        return pendingCatalogRelatedAssets;
    }

    function getToBeRenderedParts(
        address targetContract,
        uint256 tokenId,
        uint64 catalogRelatedAssetId
    ) public view returns (ToBeRenderedPart[] memory) {
        {
            (bool isValid, string memory reason) = LightmValidatorLib
                .isAValidEquippableContract(targetContract);

            if (!isValid) revert(reason);
        }
        {
            (bool isValid, string memory reason) = LightmValidatorLib
                .isAValidCatalogInstance(
                    targetContract,
                    tokenId,
                    catalogRelatedAssetId
                );

            if (!isValid) revert(reason);
        }

        ILightmEquippable.CatalogRelatedAsset memory selfBRA = ILightmEquippable(
            targetContract
        ).getCatalogRelatedAsset(catalogRelatedAssetId);

        uint64[] memory partIds = selfBRA.partIds;

        uint256 len = partIds.length;

        ToBeRenderedPart[] memory toBeRenderedParts = new ToBeRenderedPart[](
            len
        );

        uint256 j;

        for (uint256 i; i < len; ) {
            IRMRKCatalog.Part memory part = IRMRKCatalog(
                selfBRA.catalogAddress
            ).getPart(partIds[i]);

            if (part.itemType == IRMRKCatalog.ItemType.Slot) {
                ILightmEquippable.SlotEquipment memory equipment;
                try
                    ILightmEquippable(targetContract).getSlotEquipment(
                        tokenId,
                        catalogRelatedAssetId,
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
                        catalogRelatedAssetId,
                        equipment
                    );

                    if (!isValid) {
                        unchecked {
                            ++i;
                        }

                        continue;
                    }
                }

                ILightmEquippable.CatalogRelatedAsset
                    memory childAsset = ILightmEquippable(
                        equipment.child.contractAddress
                    ).getCatalogRelatedAsset(equipment.childCatalogRelatedAssetId);

                address childAssetCatalogAddress = childAsset.catalogAddress;
                bool childAssetIsCatalog = childAssetCatalogAddress != address(0)
                    ? IERC165(childAssetCatalogAddress).supportsInterface(
                        type(IRMRKCatalog).interfaceId
                    )
                    : false;

                toBeRenderedParts[j] = ToBeRenderedPart({
                    id: partIds[i],
                    childAssetCatalogAddress: childAssetIsCatalog
                        ? childAssetCatalogAddress
                        : address(0),
                    zIndex: part.z,
                    metadataURI: childAsset.metadataURI,
                    origin: Origin({
                        contractAddress: equipment.child.contractAddress,
                        tokenId: equipment.child.tokenId,
                        assetId: equipment.childCatalogRelatedAssetId
                    })
                });
            } else if (part.itemType == IRMRKCatalog.ItemType.Fixed) {
                toBeRenderedParts[j] = ToBeRenderedPart({
                    id: partIds[i],
                    childAssetCatalogAddress: address(0),
                    zIndex: part.z,
                    metadataURI: part.metadataURI,
                    origin: Origin({
                        contractAddress: address(0),
                        tokenId: 0,
                        assetId: uint64(0)
                    })
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
