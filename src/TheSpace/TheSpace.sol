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
 * - User buy pixel: call [`bid` function](./IHarbergerMarket.md) on `HarbergerMarket` contract.
 * - User set pixel price: call [`setPrice` function](./IHarbergerMarket.md) on `HarbergerMarket` contract.
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

    /**
     * @dev Pixel object.
     */
    struct Pixel {
        uint256 tokenId;
        uint256 price;
        uint256 lastTaxCollection;
        uint256 ubi;
        address owner;
        uint256 color;
    }

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
        uint256 bidPrice_,
        uint256 newPrice_,
        uint256 color_
    ) external {
        bid(tokenId_, bidPrice_);
        setPrice(tokenId_, newPrice_);
        setColor(tokenId_, color_);
    }

    /**
     * @notice Get pixel info.
     */
    function getPixel(uint256 tokenId_) external view returns (Pixel memory pixel) {
        pixel = Pixel(
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
     * @dev Emits {Color} event.
     */
    function setColor(uint256 tokenId, uint256 color) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert Unauthorized();

        pixelColor[tokenId] = color;
        emit Color(tokenId, color, ownerOf(tokenId));
    }

    /**
     * @notice Get color for a pixel.
     */
    function getColor(uint256 tokenId) public view returns (uint256) {
        return pixelColor[tokenId];
    }

    /**
     * @notice Get owned tokens for a user.
     * @dev offset based pagination
     */
    function getTokensByOwner(
        address owner,
        uint256 limit,
        uint256 offset
    ) external view returns (uint256[] memory) {
        if (limit == 0) {
            return new uint256[](0);
        }
        uint256 total = balanceOf(owner);
        if (offset >= total) {
            return new uint256[](0);
        }
        uint256 left = total - offset;
        uint256 pageSize = left > limit ? limit : left;

        uint256[] memory tokens = new uint256[](pageSize);

        for (uint256 i = 0; i < pageSize; i++) {
            uint256 tokenIndex = i + offset;
            tokens[i] = tokenOfOwnerByIndex(owner, tokenIndex);
        }

        return tokens;
    }
}
