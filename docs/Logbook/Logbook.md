## `Logbook`

### `onlyLogbookOwner(uint256 tokenId_)`

Throws if called by any account other than the logbook owner.

## Functions

### `constructor(string name_, string symbol_)` (public)

### `setTitle(uint256 tokenId_, string title_)` (external)

Set logbook title

Access Control: logbook owner
Emits a {SetTitle} event

### `setDescription(uint256 tokenId_, string description_)` (external)

Set logbook description

Access Control: logbook owner
Emits a {SetDescription} event

### `setForkPrice(uint256 tokenId_, uint256 amount_)` (external)

Set logbook fork price

Access Control: logbook owner
Emits a {SetForkPrice} event

### `multicall(bytes[] data) → bytes[] results` (external)

Batch calling methods of this contract

### `publish(uint256 tokenId_, string content_)` (external)

Publish a new log in a logbook

Access Control: logbook owner
Emits a {Publish} event

### `fork(uint256 tokenId_, uint32 endAt_) → uint256 tokenId` (external)

Pay to fork a logbook

Emits {Fork} and {Pay} events

### `forkWithCommission(uint256 tokenId_, uint32 endAt_, address commission_, uint256 commissionBPS_) → uint256 tokenId` (external)

Pay to fork a logbook with commission

Emits {Fork} and {Pay} events

### `donate(uint256 tokenId_)` (external)

Donate to a logbook

Emits {Donate} and {Pay} events

### `donateWithCommission(uint256 tokenId_, address commission_, uint256 commissionBPS_)` (external)

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

### `turnOnPublicSale()` (external)

Turn on public sale

Access Control: contract deployer

### `turnOffPublicSale()` (external)

Turn off public sale

Access Control: contract deployer

### `tokenURI(uint256 tokenId_) → string` (public)

### `_logs(uint256 tokenId_) → bytes32[] contentHashes` (internal)

Get logs of a book

### `_mint(address to) → uint256 tokenId` (internal)

### `_fork(uint256 tokenId_, uint32 endAt_) → struct Logbook.Book book, uint256 newTokenId` (internal)

### `_splitRoyalty(uint256 tokenId_, struct Logbook.Book book_, uint256 amount_, enum IRoyalty.RoyaltyPurpose purpose_, address commission_, uint256 commissionBPS_)` (internal)

Split royalty payments

No repetitive checks, please make sure all arguments are valid

### `_generateSVGofTokenById(uint256 tokenId_) → string svg` (internal)

Generate SVG image by token id

### `_toString(uint256 value) → string` (internal)

### `_afterTokenTransfer(address from, address to, uint256 tokenId)` (internal)

### `Log`

address
author

uint256
tokenId

### `Book`

uint32
endAt

uint32
logCount

uint192
createdAt

uint256
from

uint256
forkPrice

bytes32[]
contentHashes

### `SplitRoyaltyFees`

uint256
commission

uint256
logbookOwner

uint256
perLogAuthor
