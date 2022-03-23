//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev Roles for controlling HarbergerMarket contract.
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
