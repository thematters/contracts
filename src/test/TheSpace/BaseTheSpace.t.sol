//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

import {TheSpace} from "../../TheSpace/TheSpace.sol";
import {TheSpaceRegistry} from "../../TheSpace/TheSpaceRegistry.sol";
import {SpaceToken} from "../../TheSpace/SpaceToken.sol";
import {IACLManager} from "../../TheSpace/IACLManager.sol";
import {ITheSpace} from "../../TheSpace/ITheSpace.sol";
import {ITheSpaceRegistry} from "../../TheSpace/ITheSpaceRegistry.sol";

contract BaseTheSpaceTest is Test {
    TheSpace internal thespace;
    SpaceToken internal currency;
    TheSpaceRegistry internal registry;

    address constant ACL_MANAGER = address(100);
    address constant MARKET_ADMIN = address(101);
    address constant TREASURY_ADMIN = address(102);

    address constant DEPLOYER = address(200);
    address constant PIXEL_OWNER = address(201);
    address constant PIXEL_OWNER_1 = address(202);
    address constant OPERATOR = address(203);
    address constant ATTACKER = address(204);
    address constant TREASURY = address(205);
    address constant TEAM = address(206);
    uint256 constant TREASURY_TOKENS = 1400000000;
    uint256 constant TEAM_TOKENS = 8600000000;

    uint256 constant PIXEL_ID = 1;
    uint256 constant TAX_WINDOW = 302400; // roughly one week
    uint256 constant PIXEL_COLOR = 11;
    uint256 public PIXEL_PRICE;

    event Price(uint256 indexed tokenId, uint256 price, address indexed owner);
    event Config(ITheSpaceRegistry.ConfigOptions indexed option, uint256 value);
    event Tax(uint256 indexed tokenId, address indexed taxpayer, uint256 amount);
    event UBI(uint256 indexed tokenId, address indexed recipient, uint256 amount);
    event Treasury(address indexed recipient, uint256 amount);
    event Deal(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);
    event Color(uint256 indexed pixelId, uint256 indexed color, address indexed owner);

    // enums
    IACLManager.Role constant ROLE_ACL_MANAGER = IACLManager.Role.aclManager;
    IACLManager.Role constant ROLE_MARKET_ADMIN = IACLManager.Role.marketAdmin;
    IACLManager.Role constant ROLE_TREASURY_ADMIN = IACLManager.Role.treasuryAdmin;

    ITheSpaceRegistry.ConfigOptions constant CONFIG_TAX_RATE = ITheSpaceRegistry.ConfigOptions.taxRate;
    ITheSpaceRegistry.ConfigOptions constant CONFIG_TREASURY_SHARE = ITheSpaceRegistry.ConfigOptions.treasuryShare;
    ITheSpaceRegistry.ConfigOptions constant CONFIG_MINT_TAX = ITheSpaceRegistry.ConfigOptions.mintTax;

    function setUp() public {
        vm.startPrank(DEPLOYER);

        // deploy space token
        currency = new SpaceToken(TREASURY, TREASURY_TOKENS, TEAM, TEAM_TOKENS);
        assertEq(currency.balanceOf(TREASURY), TREASURY_TOKENS * (10**uint256(currency.decimals())));
        assertEq(currency.balanceOf(TEAM), TEAM_TOKENS * (10**uint256(currency.decimals())));

        PIXEL_PRICE = 1000 * (10**uint256(currency.decimals()));

        // deploy the space
        vm.expectEmit(true, false, false, false);
        emit Config(CONFIG_TAX_RATE, 0);
        vm.expectEmit(true, false, false, false);
        emit Config(CONFIG_TREASURY_SHARE, 0);
        vm.expectEmit(true, false, false, false);
        emit Config(CONFIG_MINT_TAX, 0);
        thespace = new TheSpace(address(currency), ACL_MANAGER, MARKET_ADMIN, TREASURY_ADMIN);
        registry = thespace.registry();

        vm.stopPrank();

        // transfer to tester
        uint256 amount = 10 * PIXEL_PRICE;
        vm.prank(TREASURY);
        currency.transfer(PIXEL_OWNER, amount);
        vm.prank(TREASURY);
        currency.transfer(PIXEL_OWNER_1, amount);

        // tester approve the space
        vm.prank(PIXEL_OWNER_1);
        currency.approve(address(registry), type(uint256).max);

        vm.prank(PIXEL_OWNER);
        currency.approve(address(registry), type(uint256).max);
    }

    function _bid() internal {
        vm.prank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, PIXEL_PRICE);
    }

    function _bid(uint256 bidPrice) internal {
        vm.expectEmit(true, true, true, false);
        emit Deal(PIXEL_ID, address(0), PIXEL_OWNER, 0);

        vm.prank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, bidPrice);
    }

    function _bid(uint256 bidPrice, uint256 newPrice) internal {
        vm.expectEmit(true, true, true, false);
        emit Price(PIXEL_ID, newPrice, PIXEL_OWNER);

        vm.startPrank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, bidPrice);
        thespace.setPrice(PIXEL_ID, newPrice);
        vm.stopPrank();
    }

    function _bidAs(address bidder, uint256 bidPrice) internal {
        vm.prank(bidder);
        thespace.bid(PIXEL_ID, bidPrice);
    }

    function _bidAs(
        address bidder,
        uint256 bidPrice,
        uint256 newPrice
    ) internal {
        vm.expectEmit(true, true, true, false);
        emit Price(PIXEL_ID, newPrice, bidder);

        vm.startPrank(bidder);
        thespace.bid(PIXEL_ID, bidPrice);
        thespace.setPrice(PIXEL_ID, newPrice);
        vm.stopPrank();
    }

    function _bidThis(uint256 tokenId, uint256 bidPrice) internal {
        vm.prank(PIXEL_OWNER);
        thespace.bid(tokenId, bidPrice);
    }

    function _rollBlock() internal {
        uint256 blockRollsTo = block.number + TAX_WINDOW;
        vm.roll(blockRollsTo);
    }

    function _setMintTax(uint256 mintTax) internal {
        vm.prank(MARKET_ADMIN);
        thespace.setTaxConfig(CONFIG_MINT_TAX, mintTax);
    }
}
