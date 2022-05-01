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
        vm.assume(newPrice <= thespace.maxPrice());

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
    function _assertEqArray(uint256[] memory a, uint256[] memory b) private {
        assert(a.length == b.length);
        for (uint256 i = 0; i < a.length; i++) {
            assertEq(a[i], b[i]);
        }
    }

    // function testGetTokensByOwner() public {
    //     uint256 tokenId1 = 100;
    //     uint256 tokenId2 = 101;
    //     uint256[] memory empty = new uint256[](0);

    //     // no tokens.
    //     assertEq(thespace.balanceOf(PIXEL_OWNER), 0);
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 0), empty);
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 1), empty);
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 0, 0), empty);

    //     // one token, get this token.
    //     _bidThis(tokenId1);
    //     uint256[] memory one = new uint256[](1);
    //     one[0] = tokenId1;
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 0), one);
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 10, 0), one);

    //     // one token, call with limit 0.
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 0, 0), empty);
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 0, 1), empty);

    //     // one token, call with offset >= tokens amount.
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 1), empty);
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 2), empty);

    //     // multi tokens, call with limit >= tokens amount.
    //     _bidThis(tokenId2);
    //     uint256[] memory all = new uint256[](2);
    //     all[0] = tokenId1;
    //     all[1] = tokenId2;
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 2, 0), all);
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 10, 0), all);

    //     // multi tokens, call with limit < tokens amount.
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 0), one);

    //     // multi tokens, call with offset >= tokens amount.
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 2, 2), empty);
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 2, 10), empty);

    //     // multi tokens, call with offset < tokens amount.
    //     uint256[] memory offset = new uint256[](1);
    //     offset[0] = tokenId2;
    //     thespace.getTokensByOwner(PIXEL_OWNER, 2, 1);
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 2, 1), offset);
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 1), offset);
    //     _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 10, 1), offset);
    // }
}
