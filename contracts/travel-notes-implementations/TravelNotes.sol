// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "../src/internalFunctionSet/LightmEquippableInternal.sol";
import "../src/access/AccessControl.sol";

library TravelNotesStorage {
    struct State {
        mapping(address => uint256) mintRecord;
        mapping(address => mapping(uint64 => uint256)) claimRecord;
        mapping(address => uint256) whitelist;
        uint256 totalSupply;
    }

    bytes32 constant STORAGE_POSITION = keccak256("travel-notes.storage");

    function getState() internal pure returns (State storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

abstract contract TravelNotesInternal is
    LightmEquippableInternal,
    AccessControlInternal
{
    error TravelNotesCanOnlyMintOne();
    error TravelNotesAlreadyClaim(uint256 tokenId, uint64 assetId);
    error TravelNotesChildrenInsufficient(uint256 tokenId);
    error TravelNotesNotInWhitelist(address poapAddress);
    error TravelNotesNotWhitelistManager();

    bytes32 public constant WHITELIST_MANAGER_ROLE =
        keccak256("WHITELIST_MANAGER_ROLE");

    function _onlyWhitelistManager() internal view {
        if (!_hasRole(WHITELIST_MANAGER_ROLE, msg.sender)) {
            revert TravelNotesNotWhitelistManager();
        }
    }

    modifier onlyWhitelistManager() {
        _onlyWhitelistManager();
        _;
    }

    function getTravelNotesState()
        internal
        pure
        returns (TravelNotesStorage.State storage)
    {
        return TravelNotesStorage.getState();
    }

    // assetId = 2, children length should > 3
    // assetId = 3, children length should > 5
    function _canClaim(uint256 tokenId, uint64 assetId) internal view {
        address _owner = _ownerOf(tokenId);

        if (msg.sender == _owner) {
            uint256 childrenLength = _childrenOf(tokenId).length;
            TravelNotesStorage.State storage tns = getTravelNotesState();

            // if already claim
            if (tns.claimRecord[msg.sender][assetId] == 1) {
                revert TravelNotesAlreadyClaim(tokenId, assetId);
            }

            if (assetId == uint64(2)) {
                if (childrenLength < 3) {
                    revert TravelNotesChildrenInsufficient(tokenId);
                }
            } else if (assetId == uint64(3)) {
                if (childrenLength < 5) {
                    revert TravelNotesChildrenInsufficient(tokenId);
                }
            }
        }
    }

    function claimNewAsset(uint256 tokenId, uint64 newAssetId) external {
        _canClaim(tokenId, newAssetId);

        uint64 toBeReplacedId = uint64(0);

        getTravelNotesState().claimRecord[msg.sender][newAssetId] = 1;

        _addAssetToToken(tokenId, newAssetId, toBeReplacedId);
        _acceptAsset(tokenId, newAssetId);
    }
}

contract TravelNotes is TravelNotesInternal {
    function setWhitelist(address poapAddress, bool open)
        external
        onlyWhitelistManager
    {
        TravelNotesStorage.State storage tns = getTravelNotesState();

        tns.whitelist[poapAddress] = open ? 1 : 0;
    }

    function totalSupply() public view returns (uint256) {
        return getTravelNotesState().totalSupply;
    }

    function addChild(
        uint256 parentTokenId,
        uint256 childTokenId,
        bytes memory data
    ) public {
        TravelNotesStorage.State storage tns = getTravelNotesState();

        if (tns.whitelist[msg.sender] == 0) {
            revert TravelNotesNotInWhitelist(msg.sender);
        }

        _addChild(parentTokenId, childTokenId, data);
        _acceptChild(parentTokenId, msg.sender, childTokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        TravelNotesStorage.State storage tns = getTravelNotesState();

        if (from == address(0) && to != address(0)) {
            tns.totalSupply += 1;
        }

        if (to == address(0) && from != address(0)) {
            tns.totalSupply -= 1;
        }
    }

    function mint() external {
        TravelNotesStorage.State storage tns = getTravelNotesState();

        if (tns.mintRecord[msg.sender] == 1) {
            revert TravelNotesCanOnlyMintOne();
        }

        uint256 nextTokenId = totalSupply() + 1;

        getTravelNotesState().mintRecord[msg.sender] = 1;

        // mint token
        _safeMint(msg.sender, nextTokenId);

        // add and accept default asset for token
        _addAssetToToken(nextTokenId, uint64(1), uint64(0));
        _acceptAsset(nextTokenId, uint64(1));
    }
}
