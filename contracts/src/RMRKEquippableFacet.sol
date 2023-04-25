// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC6220.sol";
import "./internalFunctionSet/RMRKEquippableInternal.sol";

contract RMRKEquippableFacet is
    IERC6220WithoutIERC5773,
    RMRKEquippableInternal,
    ReentrancyGuard
{
    /**
     * @inheritdoc IERC6220WithoutIERC5773
     */
    function equip(
        IntakeEquip memory data
    ) public virtual onlyApprovedOrOwner(data.tokenId) nonReentrant {
        _equip(data);
    }

    /**
     * @inheritdoc IERC6220WithoutIERC5773
     */
    function unequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _unequip(tokenId, assetId, slotPartId);
    }

    /**
     * @inheritdoc IERC6220WithoutIERC5773
     */
    function isChildEquipped(
        uint256 tokenId,
        address childAddress,
        uint256 childId
    ) public view virtual returns (bool) {
        return _isChildEquipped(tokenId, childAddress, childId);
    }

    /**
     * @inheritdoc IERC6220WithoutIERC5773
     */
    function canTokenBeEquippedWithAssetIntoSlot(
        address parent,
        uint256 tokenId,
        uint64 assetId,
        uint64 slotId
    ) public view virtual returns (bool) {
        return
            _canTokenBeEquippedWithAssetIntoSlot(
                parent,
                tokenId,
                assetId,
                slotId
            );
    }

    /**
     * @inheritdoc IERC6220WithoutIERC5773
     */
    function getAssetAndEquippableData(
        uint256 tokenId,
        uint64 assetId
    )
        public
        view
        virtual
        returns (string memory, uint64, address, uint64[] memory)
    {
        return _getAssetAndEquippableData(tokenId, assetId);
    }

    /**
     * @inheritdoc IERC6220WithoutIERC5773
     */
    function getEquipment(
        uint256 tokenId,
        address targetCatalogAddress,
        uint64 slotPartId
    ) public view virtual returns (Equipment memory) {
        return _getEquipment(tokenId, targetCatalogAddress, slotPartId);
    }
}
