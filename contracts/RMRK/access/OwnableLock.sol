// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
Minimal ownable lock
*/
error RMRKLocked();

/**
 * @title OwnableLock
 * @notice A minimal ownable lock smart contract.
 */
contract OwnableLock is Ownable {
    bool private lock;

    /**
     * @dev Reverts if the lock flag is set to true.
     */
    modifier notLocked() {
        if (getLock()) revert RMRKLocked();
        _;
    }

    /**
     * @notice Locks the operation.
     * @dev Once locked, functions using `notLocked` modifier cannot be executed.
     */
    function setLock() external onlyOwner {
        lock = true;
    }

    /**
     * @notice Used to retrieve the status of a lockable smart contract.
     * @return bool A boolean value signifying whether the smart contract has been locked
     */
    function getLock() public view returns (bool) {
        return lock;
    }
}
