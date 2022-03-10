//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./HarbergerMarket.sol";

/**
 * @dev _The Space_ is a pixel space owned by a decentralized autonomous organization (DAO), where members can tokenize, own, trade and color pixels. Pixels are tokenized as ERC721 tokens and traded under Harberger tax, while members receive dividend based on the share of pixels they own.
 *
 * ### Contracts
 *
 * ![The Space Contracts Relationship](./TheSpaceContracts.png "The Space Contracts Relationship")
 *
 * ### Use Cases
 *
 * #### Trading
 *
 * - User needs to call `approve` on currency contract before starting. If there is not sufficient allowance for taxing, the corresponding assets are defaulted.
 * - User buy land: call [`bid` function](./HarbergerMarket.md) on `HarbergerMarket` contract.
 * - User set land price: call [`price` function](./HarbergerMarket.md) on `HarbergerMarket` contract.
 *
 * #### Setting Content
 *
 * - Frontend renders pixel canvas: fetch [`Color` events](./TheSpace.md) from `TheSpace` contract.
 * - User color an array of pixels: call [`setColors` function](./TheSpace.md) on `TheSpace` contract.
 * - Frontend fetch content / metadata URI: call [`tokenURI` function](./Property.md) on `Property` contract.
 * - User set token content: call [`setTokenURI` function](./Property.md) on `Property` contract.
 */

contract TheSpace is HarbergerMarket {
    error Unauthorized();

    /**
     * @dev Emitted when the color of a pixel is updated.
     */
    event Color(uint256 indexed pixelId, uint256 color);

    constructor(
        string memory propertyName_,
        string memory propertySymbol_,
        address currencyAddress_,
        uint256 taxRate_,
        uint256 totalSupply_
    ) HarbergerMarket(propertyName_, propertySymbol_, currencyAddress_) {}

    /**
     * @dev Bid pixel, then set price and color.
     */
    function setPixel(
        uint256 tokenId,
        uint256 bid,
        uint256 price,
        uint256 color
    ) external {
        this.bid(tokenId, bid);
        this.setPrice(tokenId, price);
        this.setColor(tokenId, color);
    }

    /**
     * @dev Set color for a pixels.
     *
     * Emits {Color} event.
     */
    function setColor(uint256 tokenId, uint256 color) external {
        if (property.ownerOf(tokenId) != msg.sender) revert Unauthorized();

        emit Color(tokenId, color);
    }
}
