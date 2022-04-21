## `ACLManager`

Access Control List Manager for HarbergerMarket contract.

There are 3 roles:

- DEFAULT_ADMIN_ROLE: default admin in OpenZeppelin AccessControl module, responsible for assigning and revoking roles of other addresses
- MARKET_ADMIN: responsible for updating tax related configuration, e.g. tax rate and treasury rate.
- TREASURY_ADMIN: responsible for withdrawing treasury from contract.

## Functions

### `constructor(address aclManager_, address marketAdmin_, address treasuryAdmin_)` (public)
