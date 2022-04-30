//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./IACLManager.sol";

contract ACLManager is IACLManager, Context {
    mapping(Role => address) private _roles;

    constructor(
        address aclManager_,
        address marketAdmin_,
        address treasuryAdmin_
    ) {
        if (aclManager_ == address(0)) revert ZeroAddress();

        _transferRole(Role.aclManager, aclManager_);
        _transferRole(Role.marketAdmin, marketAdmin_);
        _transferRole(Role.treasuryAdmin, treasuryAdmin_);
    }

    /**
     * @dev Throws if called by any address other than the role address.
     */
    modifier onlyRole(Role role) {
        if (!_hasRole(role, _msgSender())) revert RoleRequired(role);
        _;
    }

    /// @inheritdoc IACLManager
    function hasRole(Role role, address account) public view returns (bool) {
        return _hasRole(role, account);
    }

    function _hasRole(Role role, address account) internal view returns (bool) {
        return _roles[role] == account;
    }

    /// @inheritdoc IACLManager
    function grantRole(Role role, address newAccount) public virtual onlyRole(Role.aclManager) {
        if (role == Role.aclManager) revert Forbidden();
        if (newAccount == address(0)) revert ZeroAddress();

        _transferRole(role, newAccount);
    }

    /// @inheritdoc IACLManager
    function transferRole(Role role, address newAccount) public virtual onlyRole(role) {
        if (newAccount == address(0)) revert ZeroAddress();

        _transferRole(role, newAccount);
    }

    /// @inheritdoc IACLManager
    function renounceRole(Role role) public virtual onlyRole(role) {
        if (role == Role.aclManager) revert Forbidden();

        _transferRole(role, address(0));
    }

    /**
     * @dev Transfers role to a new account (`newAccount`).
     * Internal function without access restriction.
     */
    function _transferRole(Role role, address newAccount) internal virtual {
        address oldAccount = _roles[role];
        _roles[role] = newAccount;
        emit RoleTransferred(role, oldAccount, newAccount);
    }
}
