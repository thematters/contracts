//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/**
 * @title The interface for `ACLManager` contract to manage _The Space_ market.
 * @notice Access Control List Manager is a role-based access control mechanism.
 * @dev Each role can be granted to an address.
 * @dev All available roles are defined in `Role` enum.
 */
interface IACLManager {
    //////////////////////////////
    /// Error types
    //////////////////////////////

    /**
     * @dev Given operation is requires a given role.
     */
    error RoleRequired(Role role);

    /**
     * @dev Given operation is forbidden.
     */
    error Forbidden();

    /**
     * @dev Given a zero address.
     */
    error ZeroAddress();

    //////////////////////////////
    /// Eevent types
    //////////////////////////////

    /**
     * @notice Role is transferred to a new address.
     * @param role Role transferred.
     * @param prevAccount Old address.
     * @param newAccount New address.
     */
    event RoleTransferred(Role indexed role, address indexed prevAccount, address indexed newAccount);

    /**
     * @notice Available roles.
     * @param aclManager: responsible for assigning and revoking roles of other addresses
     * @param marketAdmin: responsible for updating configuration, e.g. tax rate or treasury rate.
     * @param treasuryAdmin: responsible for withdrawing treasury from contract.
     */
    enum Role {
        aclManager,
        marketAdmin,
        treasuryAdmin
    }

    /**
     * @notice Returns `true` if `account` has been granted `role`.
     */
    function hasRole(Role role, address account) external returns (bool);

    /**
     * @notice Grant role to a account (`newAccount`).
     * @dev Cannot grant `Role.aclManager`.
     *
     * @dev Access: only `Role.aclManager`.
     * @dev Throws: `RoleRequired`, `Forbidden` or `ZeroAddress` error.
     */
    function grantRole(Role role, address newAccount) external;

    /**
     * @notice Transfers role to a new account (`newAccount`).
     * @dev Acces: only current role address.
     * @dev Throws: `RoleRequired`, or `ZeroAddress` error.
     */
    function transferRole(Role role, address newAccount) external;

    /**
     * @notice Revokes role from the role address.
     * @dev `Role.aclManager` can not be revoked.
     *
     * @dev Access: only current role address.
     * @dev Throws: `RoleRequired` or `Forbidden` error.
     */
    function renounceRole(Role role) external;
}
