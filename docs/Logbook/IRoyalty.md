## `IRoyalty`

## Functions

### `withdraw()` (external)

Withdraw royalty fees

Emits a {Withdraw} event

### `getBalance(address account_) → uint256` (external)

Get balance of a given address

## Events

### `Pay(uint256 tokenId, address sender, address recipient, uint256 amount, enum IRoyalty.RoyaltyPurpose purpose)`

Emitted when a royalty payment is made

### `Withdraw(address account, uint256 amount)`

Emitted when a withdrawal is made

### `RoyaltyPurpose`
