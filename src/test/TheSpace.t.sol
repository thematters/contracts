//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import {DSTest} from "ds-test/test.sol";

import {console} from "./utils/Console.sol";
import {Hevm} from "./utils/Hevm.sol";

import {TheSpace} from "../TheSpace/TheSpace.sol";
import {SpaceToken} from "../TheSpace/SpaceToken.sol";
import {Property} from "../TheSpace/Property.sol";

contract TheSpaceTest is DSTest {
    TheSpace private thespace;
    SpaceToken private currency;
    Property private pixels;

    Hevm constant vm = Hevm(HEVM_ADDRESS);

    address constant DEPLOYER = address(176);
    address constant PIXEL_OWNER = address(177);
    address constant ATTACKER = address(178);
    uint256 constant PIXEL_ID = 1;
    uint256 constant TAX_WINDOW = 302400; // roughly one week
    uint256 PIXEL_PRICE;

    event Price(uint256 indexed tokenId, uint256 price, address owner);
    event Color(uint256 indexed pixelId, uint256 color, address owner);
    event Tax(uint256 indexed tokenId, uint256 amount);

    function setUp() public {
        vm.prank(DEPLOYER);

        // deploy space token
        currency = new SpaceToken();
        PIXEL_PRICE = 1000 * (10**uint256(currency.decimals()));

        // deploy the space
        vm.prank(DEPLOYER);
        thespace = new TheSpace(address(currency));
        pixels = thespace.property();

        // transfer to tester
        vm.prank(DEPLOYER);
        currency.transfer(PIXEL_OWNER, 1000000);

        // tester approve the space
        vm.prank(PIXEL_OWNER);
        currency.approve(address(thespace), type(uint256).max);
    }

    function _bid() private {
        vm.prank(PIXEL_OWNER);

        // bid and mint token with 0 price
        thespace.bid(PIXEL_ID, 0);
    }

    function _price() private {
        _bid();

        vm.prank(PIXEL_OWNER);
        thespace.setPrice(PIXEL_ID, PIXEL_PRICE);
    }

    function _collectTax() private {
        vm.prank(PIXEL_OWNER);

        thespace.collectTax(PIXEL_ID);
    }

    function testBid() public {
        _bid();
        assertEq(pixels.balanceOf(PIXEL_OWNER), 1);
    }

    function testSetPrice() public {
        _bid();

        vm.prank(PIXEL_OWNER);
        vm.expectEmit(true, true, true, false);
        emit Price(PIXEL_ID, PIXEL_PRICE, PIXEL_OWNER);
        thespace.setPrice(PIXEL_ID, PIXEL_PRICE);

        assertEq(thespace.getPrice(PIXEL_ID), PIXEL_PRICE);
    }

    function testSetColor() public {
        _bid();

        uint256 color = 5;

        vm.prank(PIXEL_OWNER);
        vm.expectEmit(true, true, true, false);
        emit Color(PIXEL_ID, color, PIXEL_OWNER);
        thespace.setColor(PIXEL_ID, color);
    }

    function testDefault() public {
        _price();

        vm.roll(block.number + TAX_WINDOW);

        currency.approve(address(thespace), 0);
        thespace.collectTax(PIXEL_ID);

        assertEq(thespace.getPrice(PIXEL_ID), 0);
        assertEq(pixels.balanceOf(PIXEL_OWNER), 0);
    }

    function testTaxCollection() public {
        _price();
        vm.roll(block.number + TAX_WINDOW);

        vm.prank(PIXEL_OWNER);
        vm.expectEmit(true, false, false, false);
        emit Tax(PIXEL_ID, 10);
        thespace.collectTax(PIXEL_ID);

        assertGt(thespace.accumulatedUBI(), 0);
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
