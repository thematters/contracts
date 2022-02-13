## `Logbook`

### `onlyLogbookOwner(uint256 tokenId_)`

Throws if called by any account other than the logbook owner.

## Functions

### `constructor(string name_, string symbol_)` (public)

### `setTitle(uint256 tokenId_, string title_)` (public)

Set logbook title

Emits a {SetTitle} event

### `setDescription(uint256 tokenId_, string description_)` (public)

Set logbook description

Emits a {SetDescription} event

### `setForkPrice(uint256 tokenId_, uint256 amount_)` (public)

Set logbook fork price

Emits a {SetForkPrice} event

### `multicall(bytes[] data) → bytes[] results` (external)

Batch calling methods of this contract

### `publish(uint256 tokenId_, string content_)` (public)

Publish a new log in a logbook

Emits a {Publish} event

### `fork(uint256 tokenId_, bytes32 contentHash_)` (public)

Pay to fork a logbook

Emits {Fork} and {Pay} events

### `donate(uint256 tokenId_)` (public)

Donate to a logbook

Emits {Donate} and {Pay} events

### `setRoyaltyBPSLogbookOwner(uint128 bps_)` (public)

Set royalty basis points of logbook owner

### `setRoyaltyBPSCommission(uint128 bps_)` (public)

Set royalty basis points of contract

### `_mint(address to) → uint256 tokenId` (internal)

### `_splitRoyalty(uint256 tokenId_, struct Logbook.Book book_, uint256 amount_, enum IRoyalty.RoyaltyPurpose purpose_)` (internal)

Split royalty payments

No repetitive checks, please making sure the logbook is valid before calling it

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
