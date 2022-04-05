## `AccessRoles`

Special roles for HarbergerMarket contract.

There are 3 roles:

- DEFAULT_ADMIN_ROLE: default admin in OpenZeppelin AccessControl module, responsible for assigning and revoking roles of other addresses
- ADMIN_ROLE: responsible for updating tax related configuration, e.g. tax rate and treasury rate.
- TREASURY_ROLE: responsible for withdrawing treasury from contract.

## Functions

### `constructor(address admin_, address treasury_)` (public)
