## `IHarbergerMarket`

ERC721-compatible contract that allows token to be traded under Harberger tax.

Market attaches one ERC20 contract as currency.

## Functions

### `setTaxConfig(enum IHarbergerMarket.ConfigOptions option_, uint256 value_)` (external)

Update current tax configuration.

ADMIN_ROLE only.

### `withdrawTreasury(address to)` (external)

Withdraw all available treasury.

TREASURY_ROLE only.

### `getPrice(uint256 tokenId_) → uint256 price` (external)

Returns the current price of a token by id.

### `setPrice(uint256 tokenId_, uint256 price_)` (external)

Set the current price of a token with id. Triggers tax settle first, price is succefully updated after tax is successfully collected.

Only token owner or approved operator. Throw `Unauthorized` or `ERC721: operator query for nonexistent token` error. Emits a {Price} event if update is successful.

### `getOwner(uint256 tokenId_) → address owner` (external)

Returns the current owner of an Harberger property with token id.

If token does not exisit, return address(0) and user can bid the token as usual.

### `bid(uint256 tokenId_, uint256 price_)` (external)

Purchase property with bid higher than current price. If bid price is higher than ask price, only ask price will be deducted.

Clear tax for owner before transfer.

### `getTax(uint256 tokenId_) → uint256 amount` (external)

Calculate outstanding tax for a token.

### `evaluateOwnership(uint256 tokenId_) → uint256 collectable, bool shouldDefault` (external)

Calculate amount of tax that can be collected, and determine if token should be defaulted.

### `settleTax(uint256 tokenId_) → bool success` (external)

Collect outstanding tax of a token and default it if needed.

Anyone can trigger this function. It could be desirable for the developer team to trigger it once a while to make sure all tokens meet their tax obligation.

### `ubiAvailable(uint256 tokenId_) → uint256 amount` (external)

Amount of UBI available for withdraw on given token.

### `withdrawUbi(uint256 tokenId_)` (external)

Withdraw all UBI on given token.

## Events

### `Price(uint256 tokenId, uint256 price, address owner)`

A token updated price.

### `Config(enum IHarbergerMarket.ConfigOptions option, uint256 value)`

Global configuration for tax is updated.

### `Tax(uint256 tokenId, address taxpayer, uint256 amount)`

Tax is collected for a token.

### `UBI(uint256 tokenId, address recipient, uint256 amount)`

UBI (universal basic income) is withdrawn for a token.

### `Bid(uint256 tokenId, address from, address to, uint256 amount)`

A token has been succefully bid.

### `ConfigOptions`
