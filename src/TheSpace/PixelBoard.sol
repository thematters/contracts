//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./HarbergerMarket.sol";

abstract contract PixelBoard is HarbergerMarket {
    /**
     * @dev Emitted when the color of a pixel is updated.
     * TBD: use uint8 for color encoding?
     */
    event Color(uint256 indexed pixelId, uint256 color);

    constructor(
        string memory assetName_,
        string memory assetSymbol_,
        address currencyAddress_,
        uint8 taxRate_,
        uint256 totalSupply_
    ) HarbergerMarket(assetName_, assetSymbol_, currencyAddress_, taxRate_, totalSupply_) {}

    /**
     * @dev Set colors in batch for an array of pixels.
     *
     * Emits {Color} events.
     */
    function setColor(uint256 tokenId_, uint256 color_) external {
        // require(asset.ownerOf(tokenId_) == msg.sender, "Pixel not owned by caller.");
        emit Color(tokenId_, color_);
    }
}
