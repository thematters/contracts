//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./HarbergerMarket.sol";

/**
 * @notice _The Space_ is a pixel space owned by a decentralized autonomous organization (DAO), where members can tokenize, own, trade and color pixels.
 * Pixels are tokenized as ERC721 tokens and traded under Harberger tax, while members receive dividend based on the share of pixels they own.
 * Trading logic of Harberger tax is defined in [`IHarbergerMarket`](./IHarbergerMarket.md).
 *
 * #### Trading
 *
 * - User needs to call `approve` on currency contract before starting. If there is not sufficient allowance for taxing, the corresponding assets are defaulted.
 * - User buy land: call [`bid` function](./IHarbergerMarket.md) on `HarbergerMarket` contract.
 * - User set land price: call [`setPrice` function](./IHarbergerMarket.md) on `HarbergerMarket` contract.
 *
 */

contract TheSpace is HarbergerMarket {
    /**
     * @notice Color data of each token.
     *
     * TODO: Combine with TokenRecord to optimize storage?
     */
    mapping(uint256 => uint256) public pixelColor;

    /**
     * @notice Emitted when the color of a pixel is updated.
     */
    event Color(uint256 indexed pixelId, uint256 indexed color, address indexed owner);

    constructor(
        address currencyAddress_,
        address admin_,
        address treasury_
    ) HarbergerMarket("Planck", "PLK", currencyAddress_, admin_, treasury_) {}

    /**
     * @notice Bid pixel, then set price and color.
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
     * @notice Get pixel info.
     */
    function getPixel(uint256 tokenId)
        external
        view
        returns (
            uint256 price,
            uint256 color,
            uint256 ubi,
            address owner
        )
    {
        return (tokenRecord[tokenId].price, pixelColor[tokenId], ubiAvailable(tokenId), getOwner(tokenId));
    }

    /**
     * @notice Set color for a pixel.
     *
     * @dev Emits {Color} event.
     */
    function setColor(uint256 tokenId, uint256 color) external {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert Unauthorized();

        pixelColor[tokenId] = color;
        emit Color(tokenId, color, ownerOf(tokenId));
    }

    /**
     * @notice Get color for a pixel.
     *
     * @dev Emits {Color} event.
     */
    function getColor(uint256 tokenId) public view returns (uint256) {
        return pixelColor[tokenId];
    }
}
