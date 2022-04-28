## `ACLManager`

### `onlyRole(enum IACLManager.Role role)`

Throws if called by any address other than the role address.

## Functions

### `constructor(address aclManager_, address marketAdmin_, address treasuryAdmin_)` (public)

### `hasRole(enum IACLManager.Role role, address account) → bool` (public)

Returns `true` if `account` has been granted `role`.

### `_hasRole(enum IACLManager.Role role, address account) → bool` (internal)

### `grantRole(enum IACLManager.Role role, address newAccount)` (public)

Grant role to a account (`newAccount`).

Can only be called by ACL Manager (`Role.aclManager`).
Cannot grant `Role.aclManager`.

### `transferRole(enum IACLManager.Role role, address newAccount)` (public)

Transfers role to a new account (`newAccount`).

Can only be called by the current role address.

### `renounceRole(enum IACLManager.Role role)` (public)

Revokes role from the role address.

Can only be called by the current role address.
`Role.aclManager` can not be revoked.

### `_transferRole(enum IACLManager.Role role, address newAccount)` (internal)

Transfers role to a new account (`newAccount`).
Internal function without access restriction.
