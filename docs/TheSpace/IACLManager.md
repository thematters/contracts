## `IACLManager`

Access Control List Manager is a role-based access control mechanism.

Each role can be granted to an address.
All available roles are defined in `Role` enum.

## Functions

### `hasRole(enum IACLManager.Role role, address account) → bool` (external)

Returns `true` if `account` has been granted `role`.

### `grantRole(enum IACLManager.Role role, address newAccount)` (external)

Grant role to a account (`newAccount`).

Can only be called by ACL Manager (`Role.aclManager`).
Cannot grant `Role.aclManager`.

### `transferRole(enum IACLManager.Role role, address newAccount)` (external)

Transfers role to a new account (`newAccount`).

Can only be called by the current role address.

### `renounceRole(enum IACLManager.Role role)` (external)

Revokes role from the role address.

Can only be called by the current role address.
`Role.aclManager` can not be revoked.

## Events

### `RoleTransferred(enum IACLManager.Role role, address prevAccount, address newAccount)`

Role is transferred to a new address.

### `Role`
