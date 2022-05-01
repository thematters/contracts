//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./BaseHarbergerMarket.t.sol";

contract TheSpaceTest is BaseHarbergerMarket {
    /**
     * @dev Pixel
     */
    function testGetNonExistingPixel() public {
        TheSpace.Pixel memory pixel = thespace.getPixel(PIXEL_ID);

        assertEq(pixel.price, 0);
        assertEq(pixel.color, 0);
        assertEq(pixel.owner, address(0));
    }

    function testGetExistingPixel() public {
        _bid(PIXEL_PRICE, PIXEL_PRICE);
        TheSpace.Pixel memory pixel = thespace.getPixel(PIXEL_ID);

        assertEq(pixel.price, PIXEL_PRICE);
        assertEq(pixel.color, 0);
        assertEq(pixel.owner, PIXEL_OWNER);
    }

    function testSetPixel(uint256 newPrice) public {
        vm.assume(newPrice <= registry.currency().totalSupply());

        _bid();

        vm.prank(PIXEL_OWNER);
        thespace.setPixel(PIXEL_ID, PIXEL_PRICE, newPrice, PIXEL_COLOR);

        assertEq(thespace.getPrice(PIXEL_ID), newPrice);
        assertEq(thespace.getColor(PIXEL_ID), PIXEL_COLOR);
    }

    function testBatchSetPixels(uint16 price, uint8 color) public {
        uint256 finalPrice = uint256(price) + 1;
        uint256 finalColor = 5;

        bytes[] memory data = new bytes[](3);

        // bid pixel
        data[0] = abi.encodeWithSignature(
            "setPixel(uint256,uint256,uint256,uint256)",
            PIXEL_ID,
            PIXEL_PRICE,
            uint256(price),
            uint256(color)
        );

        // set price
        data[1] = abi.encodeWithSignature(
            "setPixel(uint256,uint256,uint256,uint256)",
            PIXEL_ID,
            PIXEL_PRICE,
            finalPrice,
            uint256(color)
        );

        // set color
        data[2] = abi.encodeWithSignature(
            "setPixel(uint256,uint256,uint256,uint256)",
            PIXEL_ID,
            PIXEL_PRICE,
            finalPrice,
            finalColor
        );

        vm.prank(PIXEL_OWNER);
        thespace.multicall(data);

        assertEq(thespace.getPrice(PIXEL_ID), finalPrice);
        assertEq(thespace.getColor(PIXEL_ID), finalColor);
    }

    /**
     * @dev Color
     */
    function testGetColor() public {}

    function testSetColor() public {
        _bid();

        uint256 color = 5;
        vm.prank(PIXEL_OWNER);
        thespace.setColor(PIXEL_ID, color);

        assertEq(thespace.getColor(PIXEL_ID), color);
    }

    function testCannotSetColorByAttacker() public {
        _bid();

        uint256 color = 6;

        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("Unauthorized()"))));
        thespace.setColor(PIXEL_ID, color);
    }

    /**
     * @dev Owner Tokens
     */
    function _assertEqArray(TheSpace.Pixel[] memory a, TheSpace.Pixel[] memory b) private {
        assert(a.length == b.length);
        for (uint256 i = 0; i < a.length; i++) {
            assertEq(a[i].tokenId, b[i].tokenId);
            assertEq(a[i].price, b[i].price);
            assertEq(a[i].lastTaxCollection, b[i].lastTaxCollection);
            assertEq(a[i].ubi, b[i].ubi);
            assertEq(a[i].owner, b[i].owner);
            assertEq(a[i].color, b[i].color);
        }
    }

    function testGetPixelsByOwnerWithNoPixels() public {
        TheSpace.Pixel[] memory empty = new TheSpace.Pixel[](0);

        assertEq(registry.balanceOf(PIXEL_OWNER), 0);
        (uint256 total0, uint256 limit0, uint256 offset0, TheSpace.Pixel[] memory pixels0) = thespace.getPixelsByOwner(
            PIXEL_OWNER,
            1,
            0
        );
        assertEq(total0, 0);
        assertEq(limit0, 1);
        assertEq(offset0, 0);
        _assertEqArray(pixels0, empty);
        (, , , TheSpace.Pixel[] memory pixels1) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 1);
        _assertEqArray(pixels1, empty);
        (, , , TheSpace.Pixel[] memory pixels2) = thespace.getPixelsByOwner(PIXEL_OWNER, 0, 0);
        _assertEqArray(pixels2, empty);
    }

    function testGetPixelsByOwnerWithOnePixel() public {
        uint256 tokenId1 = 100;
        TheSpace.Pixel[] memory empty = new TheSpace.Pixel[](0);
        TheSpace.Pixel[] memory one = new TheSpace.Pixel[](1);
        _bidThis(tokenId1, PIXEL_PRICE);
        one[0] = thespace.getPixel(tokenId1);

        assertEq(registry.balanceOf(PIXEL_OWNER), 1);
        // get this pixel
        (uint256 total0, uint256 limit0, uint256 offset0, TheSpace.Pixel[] memory pixels0) = thespace.getPixelsByOwner(
            PIXEL_OWNER,
            1,
            0
        );
        assertEq(total0, 1);
        assertEq(limit0, 1);
        assertEq(offset0, 0);
        _assertEqArray(pixels0, one);
        (, , , TheSpace.Pixel[] memory pixels1) = thespace.getPixelsByOwner(PIXEL_OWNER, 10, 0);
        _assertEqArray(pixels1, one);
        // query with limit=0
        (uint256 total2, uint256 limit2, , TheSpace.Pixel[] memory pixels2) = thespace.getPixelsByOwner(
            PIXEL_OWNER,
            0,
            0
        );
        assertEq(total2, 1);
        assertEq(limit2, 0);
        _assertEqArray(pixels2, empty);
        (, , , TheSpace.Pixel[] memory pixels3) = thespace.getPixelsByOwner(PIXEL_OWNER, 0, 1);
        _assertEqArray(pixels3, empty);
        // query with offset>=total
        (, , , TheSpace.Pixel[] memory pixels4) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 1);
        _assertEqArray(pixels4, empty);
        (, , , TheSpace.Pixel[] memory pixels5) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 2);
        _assertEqArray(pixels5, empty);
    }

    function testGetPixelsPageByOwnerWithPixels() public {
        uint256 tokenId1 = 100;
        uint256 tokenId2 = 101;
        TheSpace.Pixel[] memory empty = new TheSpace.Pixel[](0);
        TheSpace.Pixel[] memory two = new TheSpace.Pixel[](2);

        _bidThis(tokenId1, PIXEL_PRICE);
        _bidThis(tokenId2, PIXEL_PRICE);
        two[0] = thespace.getPixel(tokenId1);
        two[1] = thespace.getPixel(tokenId2);

        // query with limit>=total
        assertEq(registry.balanceOf(PIXEL_OWNER), 2);
        (uint256 total0, uint256 limit0, uint256 offset0, TheSpace.Pixel[] memory pixels0) = thespace.getPixelsByOwner(
            PIXEL_OWNER,
            2,
            0
        );
        assertEq(total0, 2);
        assertEq(limit0, 2);
        assertEq(offset0, 0);
        _assertEqArray(pixels0, two);
        (, , , TheSpace.Pixel[] memory pixels1) = thespace.getPixelsByOwner(PIXEL_OWNER, 10, 0);
        _assertEqArray(pixels1, two);

        // query with 0<limit<total
        TheSpace.Pixel[] memory pixelsPage1 = new TheSpace.Pixel[](1);
        TheSpace.Pixel[] memory pixelsPage2 = new TheSpace.Pixel[](1);
        pixelsPage1[0] = thespace.getPixel(tokenId1);
        pixelsPage2[0] = thespace.getPixel(tokenId2);
        (uint256 total2, , , TheSpace.Pixel[] memory pixels2) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 0);
        assertEq(total2, 2);
        _assertEqArray(pixels2, pixelsPage1);
        (, , , TheSpace.Pixel[] memory pixels3) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 1);
        _assertEqArray(pixels3, pixelsPage2);
        // query with offset>=total
        (, , , TheSpace.Pixel[] memory pixels4) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 2);
        _assertEqArray(pixels4, empty);
        (, , , TheSpace.Pixel[] memory pixels5) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 10);
        _assertEqArray(pixels5, empty);
    }
}
