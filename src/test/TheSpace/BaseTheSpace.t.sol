//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

import {TheSpace} from "../../TheSpace/TheSpace.sol";
import {SpaceToken} from "../../TheSpace/SpaceToken.sol";
import {IACLManager} from "../../TheSpace/IACLManager.sol";
import {IHarbergerMarket} from "../../TheSpace/IHarbergerMarket.sol";

contract BaseTheSpaceTest is Test {
    TheSpace internal thespace;
    SpaceToken internal currency;

    address constant ACL_MANAGER = address(173);
    address constant MARKET_ADMIN = address(174);
    address constant TREASURY_ADMIN = address(175);
    address constant DEPLOYER = address(176);
    address constant PIXEL_OWNER = address(177);
    address constant ATTACKER = address(178);
    uint256 constant TOTAL_SUPPLY = 1000000;
    uint256 constant PIXEL_ID = 1;
    uint256 constant TAX_WINDOW = 302400; // roughly one week
    uint256 constant PIXEL_COLOR = 11;
    uint256 PIXEL_PRICE;
    uint256 MINT_TAX;

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
        thespace = new TheSpace(address(currency), ACL_MANAGER, MARKET_ADMIN, TREASURY_ADMIN);
        MINT_TAX = thespace.taxConfig(CONFIG_MINT_TAX);

        // transfer to tester
        uint256 amount = 10000 * (10**uint256(currency.decimals()));
        currency.transfer(PIXEL_OWNER, amount);
        vm.stopPrank();

        // tester approve the space
        vm.startPrank(PIXEL_OWNER);
        currency.approve(address(thespace), type(uint256).max);
    }

    function _bid() internal {
        // bid and mint token with 1 $SPACE
        thespace.bid(PIXEL_ID, MINT_TAX);
    }

    function _bidThis(uint256 tokenId) internal {
        // bid and mint token with 1 $SPACE
        thespace.bid(tokenId, MINT_TAX);
    }

    function _price() internal {
        _bid();
        thespace.setPrice(PIXEL_ID, PIXEL_PRICE);
    }

    function _settleTax() internal {
        thespace.settleTax(PIXEL_ID);
    }
}
