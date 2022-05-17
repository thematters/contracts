## `TheSpace`

## Functions

### `constructor(address currencyAddress_, address aclManager_, address marketAdmin_, address treasuryAdmin_)` (public)

### `supportsInterface(bytes4 interfaceId_) → bool` (external)

See {IERC165-supportsInterface}.

### `upgradeTo(address newImplementation)` (external)

Switch logic contract to another one.

Access: only `Role.aclManager`.
Throws: `RoleRequired` error.

### `setTotalSupply(uint256 totalSupply_)` (external)

Configuration / Admin

### `setTaxConfig(enum ITheSpaceRegistry.ConfigOptions option_, uint256 value_)` (external)

Update current tax configuration.

Access: only `Role.marketAdmin`.
Emits: `Config` event.
Throws: `RoleRequired` error.

### `withdrawTreasury(address to_)` (external)

Withdraw all available treasury.

Access: only `Role.treasuryAdmin`.
Throws: `RoleRequired` error.

### `getPixel(uint256 tokenId_) → struct ITheSpaceRegistry.Pixel pixel` (external)

Get pixel info.

### `_getPixel(uint256 tokenId_) → struct ITheSpaceRegistry.Pixel pixel` (internal)

### `setPixel(uint256 tokenId_, uint256 bidPrice_, uint256 newPrice_, uint256 color_)` (external)

Bid pixel, then set price and color.

Throws: inherits from `bid` and `setPrice`.

### `setColor(uint256 tokenId_, uint256 color_)` (public)

Set color for a pixel.

Access: only token owner or approved operator.
Throws: `Unauthorized` or `ERC721: operator query for nonexistent token` error.
Emits: `Color` event.

### `_setColor(uint256 tokenId_, uint256 color_, address owner_)` (internal)

### `getColor(uint256 tokenId) → uint256 color` (public)

Get color for a pixel.

### `getPixelsByOwner(address owner_, uint256 limit_, uint256 offset_) → uint256 total, uint256 limit, uint256 offset, struct ITheSpaceRegistry.Pixel[] pixels` (external)

Get pixels owned by a given address.

offset-based pagination

### `getPrice(uint256 tokenId_) → uint256 price` (public)

Returns the current price of a token by id.

### `_getPrice(uint256 tokenId_) → uint256` (internal)

### `setPrice(uint256 tokenId_, uint256 price_)` (public)

Set the current price of a token with id. Triggers tax settle first, price is succefully updated after tax is successfully collected.

Access: only token owner or approved operator.
Throws: `Unauthorized` or `ERC721: operator query for nonexistent token` error.
Emits: `Price` event.

### `getOwner(uint256 tokenId_) → address owner` (public)

Returns the current owner of an Harberger property with token id.

If token does not exisit, return zero address and user can bid the token as usual.

### `bid(uint256 tokenId_, uint256 price_)` (public)

Purchase property with bid higher than current price.
If bid price is higher than ask price, only ask price will be deducted.

Clear tax for owner before transfer.

Throws: `PriceTooLow` or `InvalidTokenId` error.
Emits: `Deal`, `Tax` events.

### `getTax(uint256 tokenId_) → uint256` (public)

Calculate outstanding tax for a token.

### `_getTax(uint256 tokenId_) → uint256` (internal)

### `evaluateOwnership(uint256 tokenId_) → uint256 collectable, bool shouldDefault` (public)

Calculate amount of tax that can be collected, and determine if token should be defaulted.

### `settleTax(uint256 tokenId_) → bool success` (public)

Collect outstanding tax of a token and default it if needed.

Anyone can trigger this function. It could be desirable for the developer team to trigger it once a while to make sure all tokens meet their tax obligation.

Throws: `PriceTooLow` or `InvalidTokenId` error.
Emits: `Tax` events.

### `ubiAvailable(uint256 tokenId_) → uint256` (public)

Amount of UBI available for withdraw on given token.

### `withdrawUbi(uint256 tokenId_)` (external)

Withdraw all UBI on given token.

Emits: `UBI` event.

### `beforeTransferByRegistry(uint256 tokenId_) → bool success` (external)

Perform before `safeTransfer` and `safeTransferFrom` by registry contract.

Collect tax and set price.

Access: only registry.
Throws: `Unauthorized` error.
