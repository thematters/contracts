//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import {DSTest} from "ds-test/test.sol";

import {console} from "./utils/Console.sol";
import {Hevm} from "./utils/Hevm.sol";

import {TheSpace} from "../TheSpace/TheSpace.sol";
import {SpaceToken} from "../TheSpace/SpaceToken.sol";

contract TheSpaceTest is DSTest {
    TheSpace private thespace;
    SpaceToken private currency;

    Hevm constant vm = Hevm(HEVM_ADDRESS);

    address constant ADMIN = address(174);
    address constant TREASURY = address(175);
    address constant DEPLOYER = address(176);
    address constant PIXEL_OWNER = address(177);
    address constant ATTACKER = address(178);
    uint256 constant PIXEL_ID = 1;
    uint256 constant TAX_WINDOW = 302400; // roughly one week
    uint256 constant PIXEL_COLOR = 11;
    uint256 PIXEL_PRICE;

    event Price(uint256 indexed tokenId, uint256 price, address owner);
    event Color(uint256 indexed pixelId, uint256 color, address owner);
    event Tax(uint256 indexed tokenId, uint256 amount);

    function setUp() public {
        vm.startPrank(DEPLOYER);

        // deploy space token
        currency = new SpaceToken();
        PIXEL_PRICE = 1000 * (10**uint256(currency.decimals()));

        // deploy the space
        thespace = new TheSpace(address(currency), ADMIN, TREASURY);

        // transfer to tester
        uint256 amount = 10000 * (10**uint256(currency.decimals()));
        currency.transfer(PIXEL_OWNER, amount);
        vm.stopPrank();

        // tester approve the space
        vm.startPrank(PIXEL_OWNER);
        currency.approve(address(thespace), type(uint256).max);
    }

    function _bid() private {
        // bid and mint token with 0 price
        thespace.bid(PIXEL_ID, 0);
    }

    function _price() private {
        _bid();
        thespace.setPrice(PIXEL_ID, PIXEL_PRICE);
    }

    function _settleTax() private {
        thespace.settleTax(PIXEL_ID);
    }

    function testBid() public {
        _bid();
        assertEq(thespace.balanceOf(PIXEL_OWNER), 1);
    }

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
        (, uint256 price, , uint256 ubi, address owner, uint256 color) = thespace.getPixel(PIXEL_ID);

        assertEq(price, 0);
        assertEq(color, 0);
        assertEq(ubi, 0);
        assertEq(owner, PIXEL_OWNER);
    }

    function evaluateOwnership() public {
        // should be defaulted if no tax can be collected
        _price();
        vm.roll(block.number + TAX_WINDOW);

        currency.approve(address(thespace), 0);

        (, bool shouldDefault) = thespace.evaluateOwnership(PIXEL_ID);

        assertTrue(shouldDefault);
    }

    function testDefault() public {
        _price();

        vm.roll(block.number + TAX_WINDOW);

        currency.approve(address(thespace), 0);
        thespace.settleTax(PIXEL_ID);

        assertEq(thespace.balanceOf(PIXEL_OWNER), 0);
    }

    function testSetPrice() public {
        _price();
        assertEq(thespace.getPrice(PIXEL_ID), PIXEL_PRICE);
    }

    function testSetPixel() public {
        _price();
        uint256 newPrice = PIXEL_PRICE + 100;
        thespace.setPixel(PIXEL_ID, PIXEL_PRICE, newPrice, PIXEL_COLOR);
        assertEq(thespace.getPrice(PIXEL_ID), newPrice);
        assertEq(thespace.getColor(PIXEL_ID), PIXEL_COLOR);
    }

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

    function testTaxCollection() public {
        _price();
        vm.roll(block.number + TAX_WINDOW);

        vm.expectEmit(true, false, false, false);
        emit Tax(PIXEL_ID, 10);

        thespace.settleTax(PIXEL_ID);

        (uint256 accumulatedUBI, , ) = thespace.treasuryRecord();
        assertGt(accumulatedUBI, 0);
    }

    // function testUBIWithdraw() public {
    //     _price();

    //     vm.roll(block.number + TAX_WINDOW);
    //     _collectTax();

    //     uint256 ubi = thespace.ubiAvailable(PIXEL_ID);

    //     assertGt(ubi, 0);
    //     // uint256 total = thespace.accumulatedUBI();

    //     // emit log_uint(ubi);
    //     // emit log_uint(total);
    // }
}
