//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./BaseTheSpace.t.sol";

contract TheSpaceTest is BaseTheSpaceTest {
    /**
     * @dev Pixel
     */
    function testGetNonExistingPixel() public {
        // unminted pixel
        (, uint256 price, , uint256 ubi, address owner, uint256 color) = thespace.getPixel(PIXEL_ID + 1);

        assertEq(price, 0);
        assertEq(color, 0);
        assertEq(ubi, 0);
        assertEq(owner, address(0));
    }

    function testGetExistingPixel() public {
        // existing pixel
        _bid();
        (, uint256 price, , , address owner, uint256 color) = thespace.getPixel(PIXEL_ID);

        assertEq(price, MINT_TAX);
        assertEq(color, 0);
        // assertEq(ubi, 0);
        assertEq(owner, PIXEL_OWNER);
    }

    function testSetPixel() public {
        _price();
        uint256 newPrice = PIXEL_PRICE + 100;
        thespace.setPixel(PIXEL_ID, PIXEL_PRICE, newPrice, PIXEL_COLOR);
        assertEq(thespace.getPrice(PIXEL_ID), newPrice);
        assertEq(thespace.getColor(PIXEL_ID), PIXEL_COLOR);
    }

    function testBatchSetPixels() public {}

    /**
     * @dev Color
     */
    function testGetColor() public {}

    function testSetColorByOnwer() public {
        _bid();

        uint256 color = 5;
        thespace.setColor(PIXEL_ID, color);

        assertEq(thespace.getColor(PIXEL_ID), color);
    }

    function testCannotSetColorByAttacker() public {
        _bid();

        uint256 color = 6;

        vm.stopPrank();
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

    function testGetTokensByOwner() public {
        uint256 tokenId1 = 100;
        uint256 tokenId2 = 101;
        uint256[] memory empty = new uint256[](0);

        // no tokens.
        assertEq(thespace.balanceOf(PIXEL_OWNER), 0);
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 0), empty);
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 1), empty);
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 0, 0), empty);

        // one token, get this token.
        _bidThis(tokenId1);
        uint256[] memory one = new uint256[](1);
        one[0] = tokenId1;
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 0), one);
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 10, 0), one);

        // one token, call with limit 0.
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 0, 0), empty);
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 0, 1), empty);

        // one token, call with offset >= tokens amount.
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 1), empty);
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 2), empty);

        // multi tokens, call with limit >= tokens amount.
        _bidThis(tokenId2);
        uint256[] memory all = new uint256[](2);
        all[0] = tokenId1;
        all[1] = tokenId2;
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 2, 0), all);
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 10, 0), all);

        // multi tokens, call with limit < tokens amount.
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 0), one);

        // multi tokens, call with offset >= tokens amount.
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 2, 2), empty);
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 2, 10), empty);

        // multi tokens, call with offset < tokens amount.
        uint256[] memory offset = new uint256[](1);
        offset[0] = tokenId2;
        thespace.getTokensByOwner(PIXEL_OWNER, 2, 1);
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 2, 1), offset);
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 1, 1), offset);
        _assertEqArray(thespace.getTokensByOwner(PIXEL_OWNER, 10, 1), offset);
    }
}
