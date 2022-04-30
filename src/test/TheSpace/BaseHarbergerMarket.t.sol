//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

import {TheSpace} from "../../TheSpace/TheSpace.sol";
import {Registry} from "../../TheSpace/Registry.sol";
import {SpaceToken} from "../../TheSpace/SpaceToken.sol";
import {IACLManager} from "../../TheSpace/IACLManager.sol";
import {IHarbergerMarket} from "../../TheSpace/IHarbergerMarket.sol";

contract BaseHarbergerMarket is Test {
    TheSpace internal thespace;
    SpaceToken internal currency;
    Registry internal registry;

    address constant ACL_MANAGER = address(100);
    address constant MARKET_ADMIN = address(101);
    address constant TREASURY_ADMIN = address(102);

    address constant DEPLOYER = address(200);
    address constant PIXEL_OWNER = address(201);
    address constant PIXEL_OWNER_1 = address(202);
    address constant OPERATOR = address(203);
    address constant ATTACKER = address(204);
    address constant TREASURY = address(205);

    uint256 constant PIXEL_ID = 1;
    uint256 constant TAX_WINDOW = 302400; // roughly one week
    uint256 constant PIXEL_COLOR = 11;
    uint256 public PIXEL_PRICE;

    event Price(uint256 indexed tokenId, uint256 price, address owner);
    event Color(uint256 indexed pixelId, uint256 indexed color, address indexed owner);
    event Tax(uint256 indexed tokenId, address indexed taxpayer, uint256 amount);
    event UBI(uint256 indexed tokenId, address indexed recipient, uint256 amount);

    // enums
    IACLManager.Role constant ROLE_ACL_MANAGER = IACLManager.Role.aclManager;
    IACLManager.Role constant ROLE_MARKET_ADMIN = IACLManager.Role.marketAdmin;
    IACLManager.Role constant ROLE_TREASURY_ADMIN = IACLManager.Role.treasuryAdmin;

    IHarbergerMarket.ConfigOptions constant CONFIG_TAX_RATE = IHarbergerMarket.ConfigOptions.taxRate;
    IHarbergerMarket.ConfigOptions constant CONFIG_TREASURY_SHARE = IHarbergerMarket.ConfigOptions.treasuryShare;
    IHarbergerMarket.ConfigOptions constant CONFIG_MINT_TAX = IHarbergerMarket.ConfigOptions.mintTax;

    function setUp() public {
        vm.startPrank(DEPLOYER);

        // deploy space token
        currency = new SpaceToken();
        PIXEL_PRICE = 1000 * (10**uint256(currency.decimals()));

        // deploy the space
        thespace = new TheSpace(1000000, address(currency), ACL_MANAGER, MARKET_ADMIN, TREASURY_ADMIN);
        registry = thespace.registry();

        // transfer to tester
        uint256 amount = 10 * PIXEL_PRICE;
        currency.transfer(PIXEL_OWNER, amount);
        currency.transfer(PIXEL_OWNER_1, amount);
        vm.stopPrank();

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
        vm.prank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, bidPrice);
    }

    function _bid(uint256 bidPrice, uint256 newPrice) internal {
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
}
