// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IRMRKNestable.sol";
import "../interfaces/IRMRKCatalog.sol";
import "../interfaces/IRMRKMultiAsset.sol";
import "../interfaces/ILightmEquippable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./RMRKLib.sol";

library LightmValidatorLib {
    using RMRKLib for uint64[];
    using Address for address;

    function _existsInUint64Arr(uint64 id, uint64[] memory idArr)
        internal
        pure
        returns (bool result)
    {
        (, result) = idArr.indexOf(id);
    }

    function _childIsIn(
        IRMRKNestable.Child memory child,
        IRMRKNestable.Child[] memory children
    ) internal pure returns (bool) {
        uint256 len = children.length;
        for (uint256 i; i < len; ) {
            if (
                child.contractAddress == children[i].contractAddress &&
                child.tokenId == children[i].tokenId
            ) {
                return true;
            }

            unchecked {
                ++i;
            }
        }

        return false;
    }

    function _validateContract(address targetContract) internal view {
        (bool result, string memory reason) = isAValidEquippableContract(
            targetContract
        );

        if (!result) {
            revert(reason);
        }
    }

    // Make sure `targetContract` is valid Equippable contract
    modifier validContract(address targetContract) {
        _validateContract(targetContract);
        _;
    }

    function version() public pure returns (string memory) {
        return "0.1.0";
    }

    function getValidChildrenOf(address targetContract, uint256 tokenId)
        public
        view
        returns (IRMRKNestable.Child[] memory validChildren)
    {
        (bool isValid, string memory reason) = isAValidNestableContract(
            targetContract
        );

        if (isValid) {
            IRMRKNestable.Child[] memory children = IRMRKNestable(
                targetContract
            ).childrenOf(tokenId);
            uint256 len = children.length;
            uint256 j;

            for (uint256 i; i < len; ) {
                IRMRKNestable.Child memory child = children[i];
                (bool childIsValid, ) = isAValidNestableContract(
                    child.contractAddress
                );

                if (childIsValid) {
                    (
                        address ownerAddr,
                        uint256 ownerTokenId,
                        bool isNft
                    ) = IRMRKNestable(child.contractAddress).directOwnerOf(
                            child.tokenId
                        );

                    if (
                        ownerAddr == targetContract &&
                        ownerTokenId == tokenId &&
                        isNft
                    ) {
                        validChildren[j] = child;
                        ++j;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        } else {
            revert(reason);
        }
    }

    /** 
        @dev This function can not avoid the completely same SlotEquipment struct
        because the cost will be higher.
        Try to do rechecking on client side or just rewrite this function in your
        implementation.
     */
    function getValidSlotEquipments(
        address targetContract,
        uint256 tokenId,
        uint64 catalogRelatedAssetId
    )
        public
        view
        validContract(targetContract)
        returns (ILightmEquippable.SlotEquipment[] memory)
    {
        ILightmEquippable tContract = ILightmEquippable(targetContract);

        // avoid `stack too deep` problem
        {
            (bool isValid, ) = isAValidCatalogInstance(
                targetContract,
                tokenId,
                catalogRelatedAssetId
            );

            if (!isValid) {
                return new ILightmEquippable.SlotEquipment[](0);
            }
        }

        ILightmEquippable.SlotEquipment[] memory slotEquipments = tContract
            .getSlotEquipments(tokenId, catalogRelatedAssetId);

        ILightmEquippable.SlotEquipment[]
            memory _validSlotEquipments = new ILightmEquippable.SlotEquipment[](
                slotEquipments.length
            );

        uint256 j;

        for (uint256 i; i < slotEquipments.length; ) {
            ILightmEquippable.SlotEquipment memory sE = slotEquipments[i];

            (bool isValid, ) = isSlotEquipmentValid(
                targetContract,
                tokenId,
                catalogRelatedAssetId,
                sE
            );

            if (isValid) {
                _validSlotEquipments[j] = sE;
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        ILightmEquippable.SlotEquipment[]
            memory validSlotEquipments = new ILightmEquippable.SlotEquipment[](
                j
            );
        validSlotEquipments = _validSlotEquipments;

        return _validSlotEquipments;
    }

    function isAValidNestableContract(address targetContract)
        public
        view
        returns (bool, string memory)
    {
        if (!targetContract.isContract()) {
            return (false, "RV:NotAValidContract");
        }

        if (
            !(
                IERC165(targetContract).supportsInterface(
                    type(IRMRKNestable).interfaceId
                )
            )
        ) {
            return (false, "RV:NotANestable");
        }

        return (true, "");
    }

    function isAValidMultiAssetContract(address targetContract)
        public
        view
        returns (bool, string memory)
    {
        if (!targetContract.isContract()) {
            return (false, "RV:NotAValidContract");
        }

        if (
            !(
                IERC165(targetContract).supportsInterface(
                    type(IRMRKMultiAsset).interfaceId
                )
            )
        ) {
            return (false, "RV:NotAMultiAsset");
        }

        return (true, "");
    }

    function isAValidCatalogContract(address targetContract)
        public
        view
        returns (bool, string memory)
    {
        if (!targetContract.isContract()) {
            return (false, "RV:NotAValidContract");
        }

        if (
            !(
                IERC165(targetContract).supportsInterface(
                    type(IRMRKCatalog).interfaceId
                )
            )
        ) {
            return (false, "RV:NotACatalog");
        }

        return (true, "");
    }

    function isAValidEquippableContract(address targetContract)
        public
        view
        returns (bool, string memory)
    {
        if (!targetContract.isContract()) {
            return (false, "RV:NotAValidContract");
        }

        if (
            !(IERC165(targetContract).supportsInterface(
                type(ILightmEquippable).interfaceId
            ) &&
                IERC165(targetContract).supportsInterface(
                    type(IRMRKNestable).interfaceId
                ) &&
                IERC165(targetContract).supportsInterface(
                    type(IRMRKMultiAsset).interfaceId
                ))
        ) {
            return (false, "RV:NotAEquippable");
        }

        return (true, "");
    }

    // Make sure the `catalogRelatedAsset` is a Catalog instance
    // !!!
    // NOTE: This function assumed that `targetContract` was a valid Equippable contract
    // !!!
    function isAValidCatalogInstance(
        address targetContract,
        uint256 tokenId,
        uint64 catalogRelatedAssetId
    ) public view returns (bool, string memory) {
        uint64[] memory activeAssetIds = IRMRKMultiAsset(targetContract)
            .getActiveAssets(tokenId);

        // `catalogRelatedAssetId` has to be in `activeAssetIds`
        if (!_existsInUint64Arr(catalogRelatedAssetId, activeAssetIds)) {
            return (false, "RV:NotInActiveAssets");
        }

        ILightmEquippable.CatalogRelatedAsset
            memory catalogRelatedAsset = ILightmEquippable(targetContract)
                .getCatalogRelatedAsset(catalogRelatedAssetId);

        address catalogContract = catalogRelatedAsset.catalogAddress;
        (bool isCatalog, ) = isAValidCatalogContract(
            catalogContract
        );

        // `catalogRelatedAsset` has to be a Catalog instance
        if (!isCatalog) {
            return (false, "RV:NotValidCatalogContract");
        }

        return (true, "");
    }

    // NOTE: This function has assumed that there are no problems
    // with parent token and its `catalogRelatedAsset`
    function isSlotEquipmentValid(
        address targetContract,
        uint256 tokenId,
        uint64 catalogRelatedAssetId,
        ILightmEquippable.SlotEquipment memory slotEquipment,
        bool checkExistingData
    ) public view returns (bool, string memory) {
        (
            bool childContractIsValid,
            string memory reason
        ) = isAValidEquippableContract(slotEquipment.child.contractAddress);
        if (childContractIsValid) {
            // The tokenId in `slotEquipment` has to equal `tokenId`
            if (slotEquipment.tokenId != tokenId) {
                return (false, "RV:TokenIdMisMatch");
            }

            // The catalogRelatedAssetId in `slotEquipment` has to equal `catalogRelatedAssetId`
            if (slotEquipment.catalogRelatedAssetId != catalogRelatedAssetId) {
                return (false, "RV:CatalogRelatedAssetIdMisMatch");
            }

            {
                (
                    address ownerAddr,
                    uint256 ownerTokenId,
                    bool isNft
                ) = IRMRKNestable(slotEquipment.child.contractAddress)
                        .directOwnerOf(slotEquipment.child.tokenId);

                // The child token's owner has to be this token
                if (
                    ownerAddr != targetContract ||
                    ownerTokenId != tokenId ||
                    !isNft
                ) {
                    return (false, "RV:WrongOwner");
                }
            }

            {
                // The child token has to be this token's accepted child
                IRMRKNestable.Child[] memory children = IRMRKNestable(
                    targetContract
                ).childrenOf(tokenId);

                if (!_childIsIn(slotEquipment.child, children)) {
                    return (false, "RV:NotInActiveChilds");
                }
            }

            {
                uint64 childCatalogRelatedAssetId = slotEquipment
                    .childCatalogRelatedAssetId;

                uint64[]
                    memory childActiveCatalogRelatedAssetIds = ILightmEquippable(
                        slotEquipment.child.contractAddress
                    ).getActiveCatalogRelatedAssets(slotEquipment.child.tokenId);

                // The child token's `catalogRelatedAssetId` has to be in child token's activeCatalogRelatedAssetIds
                if (
                    !_existsInUint64Arr(
                        childCatalogRelatedAssetId,
                        childActiveCatalogRelatedAssetIds
                    )
                ) {
                    return (false, "RV:NotInActiveAssets");
                }
            }

            {
                ILightmEquippable.CatalogRelatedAsset
                    memory catalogRelatedAsset = ILightmEquippable(targetContract)
                        .getCatalogRelatedAsset(catalogRelatedAssetId);

                ILightmEquippable.CatalogRelatedAsset
                    memory childCatalogRelatedAsset = ILightmEquippable(
                        slotEquipment.child.contractAddress
                    ).getCatalogRelatedAsset(
                            slotEquipment.childCatalogRelatedAssetId
                        );

                // 1. The child's `targetCatalogAddress` has to be `catalogRelatedAsset.catalogAddress`
                // 2. The child's `targetSlotId` has to be in `catalogRelatedAsset.partIds`,
                // 3. This child collection should be allowed to be equipped on the `targetSlotId` by checking `catalogContract`
                // 4?. The slot can only equip one asset -- NOTE:
                //     This check is controlled by `checkExistingData`, only be set to `true` when validate
                //     the data which was already stored
                if (
                    childCatalogRelatedAsset.targetCatalogAddress !=
                    catalogRelatedAsset.catalogAddress
                ) {
                    return (false, "RV:WrongTargetCatalogAddress");
                }
                if (
                    !_existsInUint64Arr(
                        childCatalogRelatedAsset.targetSlotId,
                        catalogRelatedAsset.partIds
                    )
                ) {
                    return (false, "RV:TargetSlotDidNotExist");
                }
                if (
                    !IRMRKCatalog(catalogRelatedAsset.catalogAddress)
                        .checkIsEquippable(
                            childCatalogRelatedAsset.targetSlotId,
                            slotEquipment.child.contractAddress
                        )
                ) {
                    return (false, "RV:TargetSlotRejected");
                }

                if (checkExistingData) {
                    try
                        ILightmEquippable(targetContract).getSlotEquipment(
                            tokenId,
                            catalogRelatedAssetId,
                            childCatalogRelatedAsset.targetSlotId
                        )
                    returns (
                        ILightmEquippable.SlotEquipment memory realSlotEquipment
                    ) {
                        if (
                            realSlotEquipment.slotId != slotEquipment.slotId ||
                            realSlotEquipment.childCatalogRelatedAssetId !=
                            slotEquipment.childCatalogRelatedAssetId ||
                            realSlotEquipment.child.contractAddress !=
                            slotEquipment.child.contractAddress ||
                            realSlotEquipment.child.tokenId !=
                            slotEquipment.child.tokenId
                        ) {
                            return (false, "RV:SlotIsOccupiedMoreThanOne");
                        }
                    } catch (bytes memory) {}
                }
            }

            // The validation is over, this is a valid slotEquipment
            return (true, "");
        }

        return (false, reason);
    }

    function isSlotEquipmentValid(
        address targetContract,
        uint256 tokenId,
        uint64 catalogRelatedAssetId,
        ILightmEquippable.SlotEquipment memory slotEquipment
    ) public view returns (bool, string memory) {
        return
            isSlotEquipmentValid(
                targetContract,
                tokenId,
                catalogRelatedAssetId,
                slotEquipment,
                false
            );
    }
}
