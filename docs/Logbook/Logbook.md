## `Logbook`

### `onlyLogbookOwner(uint256 tokenId_)`

Throws if called by any account other than the logbook owner.

## Functions

### `constructor(string name_, string symbol_)` (public)

### `setTitle(uint256 tokenId_, string title_)` (public)

Set logbook title

Access Control: logbook owner
Emits a {SetTitle} event

### `setDescription(uint256 tokenId_, string description_)` (public)

Set logbook description

Access Control: logbook owner
Emits a {SetDescription} event

### `setForkPrice(uint256 tokenId_, uint256 amount_)` (public)

Set logbook fork price

Access Control: logbook owner
Emits a {SetForkPrice} event

### `multicall(bytes[] data) → bytes[] results` (external)

Batch calling methods of this contract

### `publish(uint256 tokenId_, string content_)` (public)

Publish a new log in a logbook

Access Control: logbook owner
Emits a {Publish} event

### `fork(uint256 tokenId_, uint256 end_) → uint256 tokenId` (public)

Pay to fork a logbook

Emits {Fork} and {Pay} events

### `forkWithCommission(uint256 tokenId_, uint256 end_, address commission_, uint128 commissionBPS_) → uint256 tokenId` (public)

Pay to fork a logbook with commission

Emits {Fork} and {Pay} events

### `donate(uint256 tokenId_)` (public)

Donate to a logbook

Emits {Donate} and {Pay} events

### `donateWithCommission(uint256 tokenId_, address commission_, uint128 commissionBPS_)` (public)

Donate to a logbook with commission

Emits {Donate} and {Pay} events

### `getLogbook(uint256 tokenId_) → uint256 forkPrice, bytes32[] contentHashes, address[] authors` (external)

Get a logbook

### `claim(address to_, uint256 logrsId_)` (external)

Claim a logbook with a Traveloggers token

Access Control: contract deployer

### `publicSaleMint() → uint256 tokenId` (external)

Mint a logbook

### `setPublicSalePrice(uint256 price_)` (external)

Set public sale

Access Control: contract deployer

### `togglePublicSale() → uint128 newPublicSale` (external)

Toggle public sale state

Access Control: contract deployer

### `_mint(address to) → uint256 tokenId` (internal)

### `_fork(uint256 tokenId_, uint256 end_) → struct Logbook.Book book, uint256 newTokenId` (internal)

### `_splitRoyalty(uint256 tokenId_, struct Logbook.Book book_, uint256 amount_, enum IRoyalty.RoyaltyPurpose purpose_, address commission_, uint128 commissionBPS_)` (internal)

Split royalty payments

No repetitive checks, please make sure all arguments are valid

### `Log`

address
author

uint256
tokenId

### `Book`

bytes32[]
contentHashes

uint256
forkPrice
