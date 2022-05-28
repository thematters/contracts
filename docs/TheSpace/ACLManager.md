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

Cannot grant `Role.aclManager`.

Access: only `Role.aclManager`.
Throws: `RoleRequired`, `Forbidden` or `ZeroAddress` error.

### `transferRole(enum IACLManager.Role role, address newAccount)` (public)

Transfers role to a new account (`newAccount`).

Acces: only current role address.
Throws: `RoleRequired`, or `ZeroAddress` error.

### `renounceRole(enum IACLManager.Role role)` (public)

Revokes role from the role address.

`Role.aclManager` can not be revoked.

Access: only current role address.
Throws: `RoleRequired` or `Forbidden` error.

### `_transferRole(enum IACLManager.Role role, address newAccount)` (internal)

Transfers role to a new account (`newAccount`).
Internal function without access restriction.
