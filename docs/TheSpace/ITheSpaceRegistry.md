## `ITheSpaceRegistry`

Storage contract for `TheSpace` contract.

It stores all states related to the market, and is owned by the TheSpace contract.
The market contract can be upgraded by changing the owner of this contract to the new implementation contract.

## Functions

### `setTotalSupply(uint256 totalSupply_)` (external)

Update total supply of ERC721 token.

### `setTaxConfig(enum ITheSpaceRegistry.ConfigOptions option_, uint256 value_)` (external)

Update global tax settings.

### `setTreasuryRecord(uint256 accumulatedUBI_, uint256 accumulatedTreasury_, uint256 treasuryWithdrawn_)` (external)

Update UBI and treasury.

### `setTokenRecord(uint256 tokenId_, uint256 price_, uint256 lastTaxCollection_, uint256 ubiWithdrawn_)` (external)

Set record for a given token.

### `setColor(uint256 tokenId_, uint256 color_, address owner_)` (external)

Set color for a given token.

### `emitTax(uint256 tokenId_, address taxpayer_, uint256 amount_)` (external)

Emit {Tax} event

### `emitPrice(uint256 tokenId_, uint256 price_, address operator_)` (external)

Emit {Price} event

### `emitUBI(uint256 tokenId_, address recipient_, uint256 amount_)` (external)

Emit {UBI} event

### `emitTreasury(address recipient_, uint256 amount_)` (external)

Emit {Treasury} event

### `emitDeal(uint256 tokenId_, address from_, address to_, uint256 amount_)` (external)

Emit {Deal} event

### `mint(address to_, uint256 tokenId_)` (external)

Mint an ERC721 token.

### `burn(uint256 tokenId_)` (external)

Burn an ERC721 token.

### `safeTransferByMarket(address from_, address to_, uint256 tokenId_)` (external)

Perform ERC721 token transfer by market contract.

### `exists(uint256 tokenId_) → bool` (external)

If an ERC721 token has been minted.

### `isApprovedOrOwner(address spender_, uint256 tokenId_) → bool` (external)

If an address is allowed to transfer an ERC721 token.

### `transferCurrency(address to_, uint256 amount_)` (external)

Perform ERC20 token transfer by market contract.

### `transferCurrencyFrom(address from_, address to_, uint256 amount_)` (external)

Perform ERC20 token transferFrom by market contract.

## Events

### `Price(uint256 tokenId, uint256 price, address owner)`

A token updated price.

### `Config(enum ITheSpaceRegistry.ConfigOptions option, uint256 value)`

Global configuration is updated.

### `TotalSupply(uint256 previousSupply, uint256 newSupply)`

Total is updated.

### `Tax(uint256 tokenId, address taxpayer, uint256 amount)`

Tax is collected for a token.

### `UBI(uint256 tokenId, address recipient, uint256 amount)`

UBI (universal basic income) is withdrawn for a token.

### `Treasury(address recipient, uint256 amount)`

Treasury is withdrawn.

### `Deal(uint256 tokenId, address from, address to, uint256 amount)`

A token has been succefully bid.

### `Color(uint256 tokenId, uint256 color, address owner)`

Emitted when the color of a pixel is updated.

### `TokenRecord`

uint256
price

uint256
lastTaxCollection

uint256
ubiWithdrawn

### `TreasuryRecord`

uint256
accumulatedUBI

uint256
accumulatedTreasury

uint256
treasuryWithdrawn

### `Pixel`

uint256
tokenId

uint256
price

uint256
lastTaxCollection

uint256
ubi

address
owner

uint256
color

### `ConfigOptions`
