## `IRoyalty`






## Functions
### `withdraw()` (external)

Withdraw royalty fees


Emits a {Withdraw} event

### `withdrawContractFees()` (external)

Withdraw contract royalty fees


Only contract owner can call
Emits a {Withdraw} event

### `getBalance(address account_) → uint256` (external)

Get balance of a given address





## Events
### `Pay(uint256 tokenId, address sender, address recipient, enum IRoyalty.RoyaltyPurpose purpose, uint256 amount)`

Emitted when a royalty payment is made




### `Withdraw(address account, uint256 amount)`

Emitted when a withdrawal is made






### `RoyaltyPurpose`








