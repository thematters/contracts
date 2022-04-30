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
        _setPrice(tokenId_, newPrice_, msg.sender);
        _setColor(tokenId_, color_, msg.sender);
    }

    /**
     * @notice Get pixel info.
     */
    function getPixel(uint256 tokenId_) external view returns (Pixel memory pixel) {
        return _getPixel(tokenId_);
    }

    function _getPixel(uint256 tokenId_) internal view returns (Pixel memory pixel) {
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
    function setColor(uint256 tokenId_, uint256 color_) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId_)) revert Unauthorized();

        _setColor(tokenId_, color_, ownerOf(tokenId_));
    }

    function _setColor(
        uint256 tokenId_,
        uint256 color_,
        address owner_
    ) public {
        pixelColor[tokenId_] = color_;
        emit Color(tokenId_, color_, owner_);
    }

    /**
     * @notice Get color for a pixel.
     */
    function getColor(uint256 tokenId) public view returns (uint256) {
        return pixelColor[tokenId];
    }

    /**
     * @notice Get owned pixels for a user using pagination.
     * @dev offset based pagination
     */
    function getPixelsByOwner(
        address owner_,
        uint256 limit_,
        uint256 offset_
    )
        external
        view
        returns (
            uint256 total,
            uint256 limit,
            uint256 offset,
            Pixel[] memory pixels
        )
    {
        uint256 total = balanceOf(owner_);
        if (limit_ == 0) {
            return (total, limit_, offset_, new Pixel[](0));
        }
        if (offset_ >= total) {
            return (total, limit_, offset_, new Pixel[](0));
        }
        uint256 left = total - offset_;
        uint256 size = left > limit_ ? limit_ : left;

        Pixel[] memory _pixels = new Pixel[](size);

        for (uint256 i = 0; i < size; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner_, i + offset_);
            pixels[i] = _getPixel(tokenId);
        }

        return (total, limit_, offset_, _pixels);
    }
}
