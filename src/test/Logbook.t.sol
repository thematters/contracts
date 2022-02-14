//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {console} from "./utils/Console.sol";
import {Hevm} from "./utils/Hevm.sol";
import {Logbook} from "../Logbook/Logbook.sol";

contract LogbookTest is DSTest {
    Logbook private logbook;

    Hevm constant vm = Hevm(HEVM_ADDRESS);

    address constant DEPLOYER = address(176);
    address constant TRAVELOGGERS_OWNER = address(177);
    address constant PUBLIC_SALE_MINTER = address(178);

    uint256 constant _PUBLIC_SALE_ON = 1;
    uint256 constant _PUBLIC_SALE_OFF = 2;

    uint256 constant CLAIM_TOKEN_START_ID = 1;
    uint256 constant CLAIM_TOKEN_END_ID = 1500;

    function setUp() public {
        vm.prank(DEPLOYER);
        logbook = new Logbook("Logbook", "LBK");
    }

    /**
     * Claim
     */
    function testClaim() public {
        // only owner
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("Ownable: caller is not the owner");
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_END_ID);

        // token has not been claimed yet
        vm.expectRevert("ERC721: owner query for nonexistent token");
        logbook.ownerOf(CLAIM_TOKEN_START_ID);

        assertEq(logbook.balanceOf(TRAVELOGGERS_OWNER), 0);

        // claim
        vm.prank(DEPLOYER);
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_START_ID);
        assertEq(logbook.ownerOf(CLAIM_TOKEN_START_ID), TRAVELOGGERS_OWNER);
        assertEq(logbook.balanceOf(TRAVELOGGERS_OWNER), 1);

        // token can't be claimed again
        vm.prank(DEPLOYER);
        vm.expectRevert("ERC721: token already minted");
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_START_ID);

        // invalid token id
        vm.prank(DEPLOYER);
        vm.expectRevert("invalid logrs id");
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_START_ID - 1);

        vm.prank(DEPLOYER);
        vm.expectRevert("invalid logrs id");
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_END_ID + 1);
    }

    /**
     * Public Sale
     */
    function testPublicSale() public {
        // not started
        vm.expectRevert("public sale is not started");
        logbook.publicSaleMint();

        // turn on: set state (1/2)
        vm.prank(DEPLOYER);
        logbook.togglePublicSale();
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("public sale is not started");
        logbook.publicSaleMint();

        // turn on: set price (2/2)
        vm.prank(DEPLOYER);
        uint256 price = 0.03 ether;
        logbook.setPublicSalePrice(price);
        assertEq(logbook.publicSalePrice(), price);

        // mint
        uint256 deployerBalanceBefore = DEPLOYER.balance;
        vm.deal(PUBLIC_SALE_MINTER, 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        uint256 tokenId = logbook.publicSaleMint{value: price}();
        assertEq(tokenId, CLAIM_TOKEN_END_ID + 1);
        assertEq(logbook.ownerOf(tokenId), PUBLIC_SALE_MINTER);

        // deployer receives ether
        assertEq(DEPLOYER.balance, deployerBalanceBefore + price);

        // not engough ether to mint
        vm.expectRevert("value too small");
        vm.prank(PUBLIC_SALE_MINTER);
        logbook.publicSaleMint{value: price - 0.01 ether}();
    }

    // Publish: gas?
    // Donate: gas? (long list)
    // Fork: gas? (long list)
    // Withdraw
    // BPS
}
