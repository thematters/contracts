## `TheSpaceRegistry`

## Functions

### `constructor(string propertyName_, string propertySymbol_, uint256 totalSupply_, uint256 taxRate_, uint256 treasuryShare_, uint256 mintTax_, address currencyAddress_)` (public)

Create Property contract, setup attached currency contract, setup tax rate.

### `totalSupply() → uint256` (public)

See {IERC20-totalSupply}.

Always return total possible amount of supply, instead of current token in circulation.

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

### `transferFrom(address from_, address to_, uint256 tokenId_)` (public)

See {IERC721-transferFrom}.

Override to collect tax and set price before transfer.

### `safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes data_)` (public)

See {IERC721-safeTransferFrom}.

### `transferCurrency(address to_, uint256 amount_)` (external)

Perform ERC20 token transfer by market contract.

### `transferCurrencyFrom(address from_, address to_, uint256 amount_)` (external)

Perform ERC20 token transferFrom by market contract.
