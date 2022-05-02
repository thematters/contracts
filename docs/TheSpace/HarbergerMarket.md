## `HarbergerMarket`

Market place with Harberger tax. This contract holds the logic of market place, while read from and write into {HarbergerRegistry}, which is the storage contact.
This contract owns a {HarbergerRegistry} contract for storage, and can be updated by transfering ownership to a new Harberger Market contract.

## Functions

### `constructor(string propertyName_, string propertySymbol_, uint256 totalSupply_, address currencyAddress_, address aclManager_, address marketAdmin_, address treasuryAdmin_)` (public)

Create Property contract, setup attached currency contract, setup tax rate

### `supportsInterface(bytes4 interfaceId_) → bool` (external)

See {IERC165-supportsInterface}.

### `upgradeContract(address newContract)` (external)

Switch logic contract to another one.

### `setTaxConfig(enum IHarbergerRegistry.ConfigOptions option_, uint256 value_)` (external)

Update current tax configuration.

ADMIN_ROLE only.

### `withdrawTreasury(address to_)` (external)

Withdraw all available treasury.

TREASURY_ROLE only.

### `getPrice(uint256 tokenId_) → uint256 price` (public)

Returns the current price of a token by id.

### `_getPrice(uint256 tokenId_) → uint256` (internal)

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
