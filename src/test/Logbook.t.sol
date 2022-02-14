//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {console} from "./utils/Console.sol";
import {Hevm} from "./utils/Hevm.sol";
import {Logbook} from "../Logbook/Logbook.sol";

contract LogbookTest is DSTest {
    Logbook private logbook;

    Hevm constant vm = Hevm(HEVM_ADDRESS);

    address constant TRAVELOGGERS_OWNER = address(176);

    uint256 constant _PUBLIC_SALE_ON = 1;
    uint256 constant _PUBLIC_SALE_OFF = 2;

    address constant PUBLIC_SALE_MINTER = address(177);

    uint256 constant CLAIM_TOKEN_START_ID = 1;
    uint256 constant CLAIM_TOKEN_END_ID = 1500;

    function setUp() public {
        logbook = new Logbook("Logbook", "LBK");
    }

    /**
     * Claim
     */
    function testClaim() public {
        // token has not been claimed yet
        vm.expectRevert("ERC721: owner query for nonexistent token");
        logbook.ownerOf(CLAIM_TOKEN_START_ID);

        assertEq(logbook.balanceOf(TRAVELOGGERS_OWNER), 0);

        // claim
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_START_ID);
        assertEq(logbook.ownerOf(CLAIM_TOKEN_START_ID), TRAVELOGGERS_OWNER);
        assertEq(logbook.balanceOf(TRAVELOGGERS_OWNER), 1);

        // token can't be claimed again
        vm.expectRevert("ERC721: token already minted");
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_START_ID);

        // invalid token id
        vm.expectRevert("invalid logrs id");
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_START_ID - 1);

        vm.expectRevert("invalid logrs id");
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_END_ID + 1);
    }

    function testPublicSale() public {
        // not started
        vm.expectRevert("public sale is not started");
        logbook.publicSaleMint();

        // turn on (1/2)
        logbook.togglePublicSale();
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("public sale is not started");
        logbook.publicSaleMint();

        // turn on (2/2)
        logbook.setPublicSalePrice(0.03 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        uint256 tokenId = logbook.publicSaleMint{value: 0.03 ether}();
        assertEq(logbook.ownerOf(tokenId), PUBLIC_SALE_MINTER);

        // deployer receives ether
        assertEq(logbook.owner().balance, 0.03 ether);

        vm.expectRevert("value too small");
        vm.prank(PUBLIC_SALE_MINTER);
        logbook.publicSaleMint{value: 0.02 ether}();
    }

    // Publish: gas?
    // Donate: gas? (long list)
    // Fork: gas? (long list)
    // Withdraw
    // BPS
}
