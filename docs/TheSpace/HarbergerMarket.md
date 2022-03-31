## `HarbergerMarket`

Market place with Harberger tax. Market attaches one ERC20 contract as currency.

## Functions

### `supportsInterface(bytes4 interfaceId_) → bool` (public)

Override interface

### `constructor(string propertyName_, string propertySymbol_, address currencyAddress_, address admin_, address treasury_)` (public)

Create Property contract, setup attached currency contract, setup tax rate

### `totalSupply() → uint256` (public)

See {IERC20-totalSupply}. Always return total possible amount of supply, instead of current token in circulation.

### `setTaxConfig(enum HarbergerMarket.ConfigOptions option_, uint256 value_)` (external)

Set the tax config for current contract. ADMIN_ROLE only.

### `withdrawTreasury()` (external)

Withdraw available treasury. TREASURY_ROLE only.

### `getPrice(uint256 tokenId_) → uint256 price` (public)

Returns the current price of an Harberger property with token id.

### `setPrice(uint256 tokenId_, uint256 price_)` (external)

Set the current price of an Harberger property with token id.

Emits a {Price} event.

### `getOwner(uint256 tokenId_) → address owner` (public)

Returns the current owner of an Harberger property with token id. If token does not exisit, return address(0).

### `bid(uint256 tokenId_, uint256 price_)` (external)

Purchase property with bid higher than current price. Clear tax for owner before transfer.

### `getTax(uint256 tokenId_) → uint256` (public)

Calculate tax for a token

### `evaluateOwnership(uint256 tokenId_) → uint256 collectable, bool shouldDefault` (public)

Calculate amount of tax that can be collected, and if token should be defaulted

### `collectTax(uint256 tokenId_) → bool` (public)

Collect outstanding property tax for a given token, put token on tax sale if obligation not met.

Emits a {Tax} event and a {Price} event (when properties are put on tax sale).

### `ubiAvailable(uint256 tokenId_) → uint256` (public)

UBI available for withdraw on given token.

### `withdrawUbi(uint256 tokenId_)` (external)

Withdraw UBI on given token.

### `_default(uint256 tokenId_)` (internal)

### `_setPrice(uint256 tokenId_, uint256 price_)` (internal)

## Events

### `Price(uint256 tokenId, uint256 price, address owner)`

Emitted when a token changes price.

### `Config(enum HarbergerMarket.ConfigOptions option, uint256 value)`

Emitted when tax configuration updates.

### `Tax(uint256 tokenId, uint256 amount)`

Emitted when tax is collected.

### `UBI(uint256 tokenId, uint256 amount)`

Emitted when UBI is distributed.

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

### `ConfigOptions`
