## `IHarbergerProperty`



Properties that are traded using Harberger tax.


  ## Functions
    ### `setMarketContract(address marketContract)` (external)

    

    Set address for attached market contract.

Emits a {MarketContract} event.

    ### `getMarketContract() → address marketContract` (external)

    

    Get address for attached market contract.

    ### `ownerByIndex(uint256 index) → address owner` (external)

    

    Return owner address by index

    ### `shareByOwner(address owner) → uint32 share` (external)

    

    Return property share by owner, unit with 1 / giga (1 ^ -9). Useful for purposes such as UBI (universal basic income).

    ### `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)` (external)

    

    Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
are aware of the ERC721 protocol to prevent tokens from being forever locked. Allows market contract as operator.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must exist and be owned by `from`.
- If the caller is not `from` or current market contract, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
- If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

Emits a {Transfer} event.

    ### `transferFrom(address from, address to, uint256 tokenId)` (external)

    

    Transfers `tokenId` token from `from` to `to`. Allows market contract as operator.

WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must be owned by `from`.
- If the caller is not `from` or current market contract, it must be approved to move this token by either {approve} or {setApprovalForAll}.

Emits a {Transfer} event.


  ## Events
    ### `MarketContract(address marketContract)`

    

    Emitted when an Harberger market contract is attached to the property.



