//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @notice Access Control List Manager for HarbergerMarket contract.
 * @dev There are 3 roles:
 * - DEFAULT_ADMIN_ROLE: default admin in OpenZeppelin AccessControl module, responsible for assigning and revoking roles of other addresses
 * - MARKET_ADMIN: responsible for updating tax related configuration, e.g. tax rate and treasury rate.
 * - TREASURY_ADMIN: responsible for withdrawing treasury from contract.
 */
contract ACLManager is AccessControl {
    bytes32 public constant TREASURY_ADMIN = keccak256("TREASURY_ADMIN");
    bytes32 public constant MARKET_ADMIN = keccak256("MARKET_ADMIN");

    constructor(
        address aclManager_,
        address marketAdmin_,
        address treasuryAdmin_
    ) {
        require(aclManager_ != address(0), "zero address");

        // default admin to control other roles
        _setupRole(DEFAULT_ADMIN_ROLE, aclManager_);

        _setupRole(MARKET_ADMIN, marketAdmin_);
        _setupRole(TREASURY_ADMIN, treasuryAdmin_);
    }
}
