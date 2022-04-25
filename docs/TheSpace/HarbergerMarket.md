## `HarbergerMarket`

Market place with Harberger tax. Market attaches one ERC20 contract as currency.

## Functions

### `constructor(string propertyName_, string propertySymbol_, address currencyAddress_, address aclManager_, address marketAdmin_, address treasuryAdmin_)` (public)

Create Property contract, setup attached currency contract, setup tax rate

### `supportsInterface(bytes4 interfaceId_) → bool` (public)

See {IERC165-supportsInterface}.

### `transferFrom(address from_, address to_, uint256 tokenId_)` (public)

See {IERC721-transferFrom}. Override to collect tax before transfer.

### `safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes data_)` (public)

See {IERC721-safeTransferFrom}. Override to collect tax before transfer.

### `totalSupply() → uint256` (public)

See {IERC20-totalSupply}. Always return total possible amount of supply, instead of current token in circulation.

### `setTaxConfig(enum IHarbergerMarket.ConfigOptions option_, uint256 value_)` (external)

Update current tax configuration.

ADMIN_ROLE only.

### `withdrawTreasury(address to)` (external)

Withdraw all available treasury.

TREASURY_ROLE only.

### `getPrice(uint256 tokenId_) → uint256 price` (public)

Returns the current price of a token by id.

### `_getPrice(uint256 tokenId_) → uint256 price` (internal)

### `setPrice(uint256 tokenId_, uint256 price_)` (public)

Set the current price of a token with id. Triggers tax settle first, price is succefully updated after tax is successfully collected.

Only token owner or approved operator. Throw `Unauthorized` or `ERC721: operator query for nonexistent token` error. Emits a {Price} event if update is successful.

### `getOwner(uint256 tokenId_) → address owner` (public)

Returns the current owner of an Harberger property with token id.

If token does not exisit, return address(0) and user can bid the token as usual.

### `bid(uint256 tokenId_, uint256 price_)` (public)

Purchase property with bid higher than current price. If bid price is higher than ask price, only ask price will be deducted.

Clear tax for owner before transfer.

### `getTax(uint256 tokenId_) → uint256` (public)

Calculate outstanding tax for a token.

### `_getTax(uint256 tokenId_) → uint256` (internal)

### `evaluateOwnership(uint256 tokenId_) → uint256 collectable, bool shouldDefault` (public)

Calculate amount of tax that can be collected, and determine if token should be defaulted.

### `settleTax(uint256 tokenId_) → bool success` (public)

Collect outstanding tax of a token and default it if needed.

Anyone can trigger this function. It could be desirable for the developer team to trigger it once a while to make sure all tokens meet their tax obligation.

### `ubiAvailable(uint256 tokenId_) → uint256` (public)

Amount of UBI available for withdraw on given token.

### `withdrawUbi(uint256 tokenId_)` (external)

Withdraw UBI on given token.

### `_setPrice(uint256 tokenId_, uint256 price_)` (internal)

Internel function to set price for a token.

### `_setPrice(uint256 tokenId_, uint256 price_, address owner)` (internal)

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
