// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721Internal.sol";
import "../interfaces/IRMRKMultiAsset.sol";
import "../interfaces/ILightmMultiAsset.sol";
import "../library/RMRKLib.sol";
import "../library/RMRKMultiAssetRenderUtils.sol";

import {MultiAssetStorage} from "./Storage.sol";

error RMRKBadPriorityListLength();
error RMRKIndexOutOfRange();
error RMRKInvalidTokenId();
error RMRKMaxPendingAssetsReached();
error RMRKNoAssetMatchingId();
error RMRKAssetAlreadyExists();
error RMRKAssetNotFoundInStorage();
error RMRKNotApprovedForAssetsOrOwner();
error RMRKApprovalForAssetsToCurrentOwner();
error RMRKApproveForAssetsCallerIsNotOwnerNorApprovedForAll();
error RMRKApproveForAssetsToCaller();
error RMRKWriteToZero();

abstract contract RMRKMultiAssetInternal is
    ERC721Internal,
    IRMRKMultiAssetEventsAndStruct,
    ILightmMultiAssetEventsAndStruct
{
    using Strings for uint256;
    using RMRKLib for uint16[];
    using RMRKLib for uint64[];
    using RMRKLib for uint128[];

    uint16 internal constant LOWEST_PRIORITY = type(uint16).max - 1;

    function getMRState()
        internal
        pure
        returns (MultiAssetStorage.State storage)
    {
        return MultiAssetStorage.getState();
    }

    function _burn(uint256 tokenId) internal virtual override {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _approveForAssets(address(0), tokenId);

        ERC721Storage.State storage s = getState();
        s._balances[owner] -= 1;
        delete s._owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _tokenURI(uint256 tokenId)
        internal
        view
        virtual
        override
        returns (string memory)
    {
        MultiAssetStorage.State storage mrs = getMRState();

        try
            RMRKMultiAssetRenderUtils.getTopAssetMetaForToken(
                address(this),
                tokenId
            )
        returns (string memory meta) {
            return meta;
        } catch (bytes memory err) {
            if (
                bytes4(err) ==
                RMRKMultiAssetRenderUtils.RMRKTokenHasNoAssets.selector
            ) {
                return mrs._fallbackURI;
            }

            revert(string(err));
        }
    }

    function _isApprovedForAssetsOrOwner(address user, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = _ownerOf(tokenId);
        return (user == owner ||
            _isApprovedForAllForAssets(owner, user) ||
            _getApprovedForAssets(tokenId) == user);
    }

    function _onlyApprovedForAssetsOrOwner(uint256 tokenId) private view {
        if (!_isApprovedForAssetsOrOwner(_msgSender(), tokenId))
            revert RMRKNotApprovedForAssetsOrOwner();
    }

    modifier onlyApprovedForAssetsOrOwner(uint256 tokenId) {
        _onlyApprovedForAssetsOrOwner(tokenId);
        _;
    }

    function _addAssetEntry(uint64 id, string memory metadataURI) internal {
        if (id == uint64(0)) revert RMRKWriteToZero();

        MultiAssetStorage.State storage state = MultiAssetStorage
            .getState();

        if (bytes(state._assets[id]).length > 0)
            revert RMRKAssetAlreadyExists();

        _beforeAddAsset(id, metadataURI);

        state._assets[id] = metadataURI;

        emit AssetSet(id);
        _afterAddAsset(id, metadataURI);
    }

    function _getAssetMetadata(uint64 assetId)
        internal
        view
        virtual
        returns (string memory)
    {
        string memory metadata = getMRState()._assets[assetId];
        if (bytes(metadata).length == 0) revert RMRKNoAssetMatchingId();

        return metadata;
    }

    function _getAssetMetaForToken(uint256 tokenId, uint256 assetIndex)
        internal
        view
        virtual
        returns (string memory)
    {
        uint64 assetId = _getActiveAssets(tokenId)[assetIndex];
        return _getAssetMetadata(assetId);
    }

    function _acceptAsset(
        MultiAssetStorage.State storage s,
        uint256 tokenId,
        uint64 assetId,
        uint256 index
    ) private {
        _beforeAcceptAsset(tokenId, index, assetId);

        uint64[] storage pendingAssets = s._pendingAssets[tokenId];

        delete s._assetsPosition[tokenId][assetId];

        pendingAssets.removeItemByIndex(index);

        if (pendingAssets.length > 0) {
            uint64 prevLastAssetId = pendingAssets[index];
            // The implementation of `removeItemByIndex` let we need to update the exchanged asset index
            s._assetsPosition[tokenId][prevLastAssetId] = index;
        }

        uint64[] storage activeAssets = s._activeAssets[tokenId];
        uint64 overwrites = s._assetOverwrites[tokenId][assetId];
        if (overwrites != uint64(0)) {
            uint256 position = s._assetsPosition[tokenId][overwrites];
            uint64 overwritesId = activeAssets[position];

            if (overwritesId == overwrites) {
                activeAssets[position] = assetId;
                s._assetsPosition[tokenId][assetId] = position;
                delete (s._tokenAssets[tokenId][overwrites]);
            } else {
                // No `overwrites` exist, set `overwrites` to 0 to run a normal accept process.
                overwrites = uint64(0);
            }
            delete (s._assetOverwrites[tokenId][assetId]);
        }

        if (overwrites == uint64(0)) {
            activeAssets.push(assetId);
            s._activeAssetPriorities[tokenId].push(LOWEST_PRIORITY);
            s._assetsPosition[tokenId][assetId] =
                s._activeAssets[tokenId].length -
                1;
        }

        emit AssetAccepted(tokenId, assetId, overwrites);

        _afterAcceptAsset(tokenId, index, assetId);
    }

    function _acceptAsset(uint256 tokenId, uint64 assetId)
        internal
        virtual
    {
        MultiAssetStorage.State storage s = getMRState();

        uint256 index = s._assetsPosition[tokenId][assetId];
        uint64[] storage tokenPendingAssets = s._pendingAssets[tokenId];

        if (index >= tokenPendingAssets.length) {
            revert RMRKIndexOutOfRange();
        }

        if (tokenPendingAssets[index] != assetId) {
            revert RMRKNoAssetMatchingId();
        }

        _acceptAsset(s, tokenId, assetId, index);
    }

    function _acceptAssetByIndex(uint256 tokenId, uint256 index)
        internal
        virtual
    {
        MultiAssetStorage.State storage s = getMRState();

        if (index >= s._pendingAssets[tokenId].length)
            revert RMRKIndexOutOfRange();
        uint64 assetId = s._pendingAssets[tokenId][index];

        _acceptAsset(s, tokenId, assetId, index);
    }

    function _rejectAsset(
        MultiAssetStorage.State storage s,
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) private {
        _beforeRejectAsset(tokenId, index, assetId);

        uint64[] storage pendingAssets = s._pendingAssets[tokenId];

        delete s._assetsPosition[tokenId][assetId];

        delete (s._assetOverwrites[tokenId][assetId]);

        pendingAssets.removeItemByIndex(index);

        if (pendingAssets.length > 0) {
            // Check the implementation of `removeItemByIndex`, the last element will exchange position with element at `index`.
            // So we should update the index of exchanged element.
            uint64 prevLastAssetId = pendingAssets[index];
            s._assetsPosition[tokenId][prevLastAssetId] = index;
        }

        s._tokenAssets[tokenId][assetId] = false;

        emit AssetRejected(tokenId, assetId);

        _afterRejectAsset(tokenId, index, assetId);
    }

    function _rejectAsset(uint256 tokenId, uint64 assetId)
        internal
        virtual
    {
        MultiAssetStorage.State storage s = getMRState();

        uint256 index = s._assetsPosition[tokenId][assetId];
        uint64[] storage tokenPendingAssets = s._pendingAssets[tokenId];

        if (index >= tokenPendingAssets.length) {
            revert RMRKIndexOutOfRange();
        }

        if (tokenPendingAssets[index] != assetId) {
            revert RMRKNoAssetMatchingId();
        }

        _rejectAsset(s, tokenId, index, assetId);
    }

    function _rejectAssetByIndex(uint256 tokenId, uint256 index)
        internal
        virtual
    {
        MultiAssetStorage.State storage s = getMRState();

        if (index >= s._pendingAssets[tokenId].length)
            revert RMRKIndexOutOfRange();
        uint64 assetId = s._pendingAssets[tokenId][index];

        _rejectAsset(s, tokenId, index, assetId);
    }

    function _rejectAllAssets(uint256 tokenId) internal virtual {
        _beforeRejectAllAssets(tokenId);

        MultiAssetStorage.State storage s = getMRState();

        uint256 len = s._pendingAssets[tokenId].length;
        for (uint256 i; i < len; ) {
            uint64 assetId = s._pendingAssets[tokenId][i];
            delete s._assetOverwrites[tokenId][assetId];

            unchecked {
                ++i;
            }
        }

        delete (s._pendingAssets[tokenId]);
        emit AssetRejected(tokenId, uint64(0));

        _afterRejectAllAssets(tokenId);
    }

    function _setPriority(uint256 tokenId, uint16[] memory priorities)
        internal
        virtual
    {
        MultiAssetStorage.State storage s = getMRState();

        uint256 length = priorities.length;
        if (length != s._activeAssets[tokenId].length)
            revert RMRKBadPriorityListLength();

        _beforeSetPriority(tokenId, priorities);

        s._activeAssetPriorities[tokenId] = priorities;

        emit AssetPrioritySet(tokenId);

        _afterSetPriority(tokenId, priorities);
    }

    function _setFallbackURI(string memory fallbackURI) internal virtual {
        MultiAssetStorage.State storage s = getMRState();

        s._fallbackURI = fallbackURI;
    }

    function _addAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 overwrites
    ) internal virtual {
        MultiAssetStorage.State storage s = getMRState();

        if (s._tokenAssets[tokenId][assetId])
            revert RMRKAssetAlreadyExists();

        if (assetId == uint64(0)) revert RMRKAssetNotFoundInStorage();

        if (s._pendingAssets[tokenId].length >= 128)
            revert RMRKMaxPendingAssetsReached();

        _beforeAddAssetToToken(tokenId, assetId, overwrites);

        s._tokenAssets[tokenId][assetId] = true;

        s._assetsPosition[tokenId][assetId] = s
            ._pendingAssets[tokenId]
            .length;

        s._pendingAssets[tokenId].push(assetId);

        if (overwrites != uint64(0)) {
            s._assetOverwrites[tokenId][assetId] = overwrites;
        }

        emit AssetAddedToToken(tokenId, assetId, overwrites);

        _afterAddAssetToToken(tokenId, assetId, overwrites);
    }

    function _getActiveAssets(uint256 tokenId)
        internal
        view
        virtual
        returns (uint64[] memory)
    {
        return getMRState()._activeAssets[tokenId];
    }

    function _getPendingAssets(uint256 tokenId)
        internal
        view
        virtual
        returns (uint64[] memory)
    {
        return getMRState()._pendingAssets[tokenId];
    }

    function _getActiveAssetPriorities(uint256 tokenId)
        internal
        view
        virtual
        returns (uint16[] memory)
    {
        return getMRState()._activeAssetPriorities[tokenId];
    }

    function _getAssetOverwrites(uint256 tokenId, uint64 assetId)
        internal
        view
        virtual
        returns (uint64)
    {
        return getMRState()._assetOverwrites[tokenId][assetId];
    }

    function _getApprovedForAssets(uint256 tokenId)
        internal
        view
        virtual
        returns (address)
    {
        _requireMinted(tokenId);

        return getMRState()._tokenApprovalsForAssets[tokenId];
    }

    function _isApprovedForAllForAssets(address owner, address operator)
        internal
        view
        virtual
        returns (bool)
    {
        return getMRState()._operatorApprovalsForAssets[owner][operator];
    }

    function _approveForAssets(address to, uint256 tokenId)
        internal
        virtual
    {
        getMRState()._tokenApprovalsForAssets[tokenId] = to;
        emit ApprovalForAssets(_ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAllForAssets(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        getMRState()._operatorApprovalsForAssets[owner][operator] = approved;
        emit ApprovalForAllForAssets(owner, operator, approved);
    }

    function _getFullAssets(uint256 tokenId)
        internal
        view
        virtual
        returns (Asset[] memory)
    {
        uint64[] memory assetIds = getMRState()._activeAssets[tokenId];
        return _getAssetsById(assetIds);
    }

    function _getFullPendingAssets(uint256 tokenId)
        internal
        view
        virtual
        returns (Asset[] memory)
    {
        uint64[] memory assetIds = getMRState()._pendingAssets[tokenId];
        return _getAssetsById(assetIds);
    }

    function _getAssetsById(uint64[] memory assetIds)
        internal
        view
        virtual
        returns (Asset[] memory)
    {
        uint256 len = assetIds.length;
        Asset[] memory assets = new Asset[](len);
        for (uint256 i; i < len; ) {
            uint64 id = assetIds[i];
            assets[i] = Asset({
                id: id,
                metadataURI: _getAssetMetadata(id)
            });

            unchecked {
                ++i;
            }
        }
        return assets;
    }

    function _beforeAddAsset(uint64 id, string memory metadataURI)
        internal
        virtual
    {}

    function _afterAddAsset(uint64 id, string memory metadataURI)
        internal
        virtual
    {}

    function _beforeAddAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 overwrites
    ) internal virtual {}

    function _afterAddAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 overwrites
    ) internal virtual {}

    function _beforeAcceptAsset(
        uint256 tokenId,
        uint256 index,
        uint256 assetId
    ) internal virtual {}

    function _afterAcceptAsset(
        uint256 tokenId,
        uint256 index,
        uint256 assetId
    ) internal virtual {}

    function _beforeRejectAsset(
        uint256 tokenId,
        uint256 index,
        uint256 assetId
    ) internal virtual {}

    function _afterRejectAsset(
        uint256 tokenId,
        uint256 index,
        uint256 assetId
    ) internal virtual {}

    function _beforeRejectAllAssets(uint256 tokenId) internal virtual {}

    function _afterRejectAllAssets(uint256 tokenId) internal virtual {}

    function _beforeSetPriority(uint256 tokenId, uint16[] memory priorities)
        internal
        virtual
    {}

    function _afterSetPriority(uint256 tokenId, uint16[] memory priorities)
        internal
        virtual
    {}
}
