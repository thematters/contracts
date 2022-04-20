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
     */
    mapping(uint256 => uint256) public pixelColor;

    /**
     * @notice Emitted when the color of a pixel is updated.
     */
    event Color(uint256 indexed pixelId, uint256 indexed color, address indexed owner);

    constructor(
        address currencyAddress_,
        address aclManager_,
        address marketAdmin_,
        address treasuryAdmin_
    ) HarbergerMarket("Planck", "PLK", currencyAddress_, aclManager_, marketAdmin_, treasuryAdmin_) {}

    /**
     * @notice Bid pixel, then set price and color.
     */
    function setPixel(
        uint256 tokenId_,
        uint256 bid_,
        uint256 price_,
        uint256 color_
    ) external {
        bid(tokenId_, bid_);
        setPrice(tokenId_, price_);
        setColor(tokenId_, color_);
    }

    /**
     * @notice Get pixel info.
     */
    function getPixel(uint256 tokenId_)
        external
        view
        returns (
            uint256 tokenId,
            uint256 price,
            uint256 lastTaxCollection,
            uint256 ubi,
            address owner,
            uint256 color
        )
    {
        return (
            tokenId_,
            tokenRecord[tokenId_].price,
            tokenRecord[tokenId_].lastTaxCollection,
            ubiAvailable(tokenId_),
            getOwner(tokenId_),
            pixelColor[tokenId_]
        );
    }

    /**
     * @notice Set color for a pixel.
     *
     * @dev Emits {Color} event.
     */
    function setColor(uint256 tokenId, uint256 color) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert Unauthorized();

        pixelColor[tokenId] = color;
        emit Color(tokenId, color, ownerOf(tokenId));
    }

    /**
     * @notice Get color for a pixel.
     *
     */
    function getColor(uint256 tokenId) public view returns (uint256) {
        return pixelColor[tokenId];
    }
}
