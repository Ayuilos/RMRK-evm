// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../interfaces/IRMRKMultiAsset.sol";
import "../interfaces/IRMRKNestable.sol";
import "../interfaces/ILightmEquippable.sol";
import "../interfaces/ILightmMintModule.sol";

library ERC721Storage {
    struct State {
        // Token name
        string _name;
        // Token symbol
        string _symbol;
        // Mapping from token ID to owner address
        mapping(uint256 => address) _owners;
        // Mapping owner address to token count
        mapping(address => uint256) _balances;
        // Mapping from token ID to approved address
        mapping(uint256 => address) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
    }

    bytes32 constant STORAGE_POSITION = keccak256("erc721.storage");

    function getState() internal pure returns (State storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

library MultiAssetStorage {
    struct State {
        // Mapping of uint64 Ids to asset object
        mapping(uint64 => string) _assets;
        // Mapping of tokenId to new asset, to asset to be replaced
        mapping(uint256 => mapping(uint64 => uint64)) _assetReplacements;
        // Mapping of tokenId to all assets
        mapping(uint256 => uint64[]) _activeAssets;
        // Mapping of tokenId to an array of asset priorities
        mapping(uint256 => uint64[]) _activeAssetPriorities;
        // Mapping of tokenId to assetId to whether the token has this asset assigned
        mapping(uint256 => mapping(uint64 => bool)) _tokenAssets;
        // Mapping of tokenId to an array of pending assets
        mapping(uint256 => uint64[]) _pendingAssets;
        // Mapping of tokenId to assetID to its position
        mapping(uint256 => mapping(uint64 => uint256)) _assetsPosition;
        // Fallback URI
        string _fallbackURI;
        // Mapping from token ID to approved address for assets
        mapping(uint256 => address) _tokenApprovalsForAssets;
        // Mapping from owner to operator approvals for assets
        mapping(address => mapping(address => bool)) _operatorApprovalsForAssets;
    }

    bytes32 constant STORAGE_POSITION = keccak256("rmrk.multiasset.storage");

    function getState() internal pure returns (State storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

library NestableStorage {
    struct State {
        // Mapping from token ID to DirectOwner struct
        mapping(uint256 => IRMRKNestable.DirectOwner) _DirectOwners;
        // Mapping of tokenId to array of active children structs
        mapping(uint256 => IRMRKNestable.Child[]) _activeChildren;
        // Mapping of tokenId to array of pending children structs
        mapping(uint256 => IRMRKNestable.Child[]) _pendingChildren;
        // Mapping of childAddress to child tokenId to child position in children array
        mapping(address => mapping(uint256 => uint256)) _posInChildArray;
    }

    bytes32 constant STORAGE_POSITION = keccak256("rmrk.nestable.storage");

    function getState() internal pure returns (State storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

library EquippableStorage {
    struct State {
        mapping(uint64 => ILightmEquippable.CatalogRelatedData) _catalogRelatedDatas;
        uint64[] _allCatalogRelatedAssetIds;
        // tokenId => catalogRelatedAssetId[]
        mapping(uint256 => uint64[]) _activeCatalogRelatedAssets;
        // tokenId => catalogRelatedAssetId => index
        mapping(uint256 => mapping(uint64 => uint256)) _activeCatalogRelatedAssetsPosition;
        ILightmEquippable.SlotEquipment[] _slotEquipments;
        // tokenId => catalogRelatedAssetId => slotId => EquipmentPointer in _slotEquipments
        mapping(uint256 => mapping(uint64 => mapping(uint64 => ILightmEquippable.EquipmentPointer))) _equipmentPointers;
        // tokenId => catalogRelatedAssetId => childContract => childTokenId => bool
        // to make sure that every catalog instance can only has one slot occupied by one child.
        // For example, you have a hat NFT which have 2 assets: 1st is for wearing on the head of human NFT,
        // 2nd is for holding on the hand of human NFT. You should never be able to let the human NFT
        // both wear and hold the hat NFT.
        mapping(uint256 => mapping(uint64 => mapping(address => mapping(uint256 => bool)))) _catalogAlreadyEquippedChild;
        // records which slots are in the equipped state
        mapping(uint256 => mapping(uint64 => uint64[])) _equippedSlots;
        // childContract => childTokenId => childCatalogRelatedAssetId => EquipmentPointer in _slotEquipments
        mapping(address => mapping(uint256 => mapping(uint64 => ILightmEquippable.EquipmentPointer))) _childEquipmentPointers;
        // records which childCatalogRelatedAssets are in the equipped state
        mapping(address => mapping(uint256 => uint64[])) _equippedChildCatalogRelatedAssets;
    }

    bytes32 constant STORAGE_POSITION = keccak256("lightm.equippable.storage");

    function getState() internal pure returns (State storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

library ERC6220Storage {
    struct State {
        // mapping of uint64 ID to asset object
        mapping(uint64 => uint64) _equippableGroupIds;
        // Mapping of `equippableGroupId` to parent contract address and valid `slotId`.
        mapping(uint64 => mapping(address => uint64)) _validParentSlots;
    }

    bytes32 constant STORAGE_POSITION = keccak256("erc6220.equippable.storage");

    function getState() internal pure returns (State storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

library CollectionMetadataStorage {
    struct State {
        string _collectionMetadata;
    }

    bytes32 constant STORAGE_POSITION =
        keccak256("rmrk.collection_metadata.storage");

    function getState() internal pure returns (State storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

library LightmImplStorage {
    struct State {
        address _owner;
    }

    bytes32 constant STORAGE_POSITION = keccak256("lightm.impl.storage");

    function getState() internal pure returns (State storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

library LightmMintModuleStorage {
    struct State {
        ILightmMintModule.MintConfig config;
        bytes32 whitelistMerkleProofRoot;
        uint256 totalSupply;
        bool allowPublicMint;
        bool allowWhitelistMint;
        mapping(address => uint64) publicMintedTokenCount;
        mapping(address => uint64) whitelistMintedTokenCount;
    }

    bytes32 constant STORAGE_POSITION = keccak256("lightm.mint.module.storage");

    function getState() internal pure returns (State storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

library ERC2981Storage {
    struct State {
        ERC2981.RoyaltyInfo _defaultRoyaltyInfo;
        mapping(uint256 => ERC2981.RoyaltyInfo) _tokenRoyaltyInfo;
    }

    bytes32 constant STORAGE_POSITION = keccak256("erc2981.storage");

    function getState() internal pure returns (State storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
