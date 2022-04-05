//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @notice Special roles for HarbergerMarket contract.
 * @dev There are 3 roles:
 * - DEFAULT_ADMIN_ROLE: default admin in OpenZeppelin AccessControl module, responsible for assigning and revoking roles of other addresses
 * - ADMIN_ROLE: responsible for updating tax related configuration, e.g. tax rate and treasury rate.
 * - TREASURY_ROLE: responsible for withdrawing treasury from contract.
 */
contract AccessRoles is AccessControl {
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(address admin_, address treasury_) {
        // default admin to control other roles
        _setupRole(DEFAULT_ADMIN_ROLE, admin_);

        _setupRole(ADMIN_ROLE, admin_);
        _setupRole(TREASURY_ROLE, treasury_);
    }
}
