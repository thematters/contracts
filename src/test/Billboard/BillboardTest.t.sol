//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./BillboardTestBase.t.sol";

contract BillboardTest is BillboardTestBase {
    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    function testUpgradeAuctionByAttacker() public {
        vm.stopPrank();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        operator.upgradeAuction(ZERO_ADDRESS);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.upgradeAuction(FAKE_CONTRACT);
    }

    function testUpgradeRegistryByAttacker() public {
        vm.stopPrank();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        operator.upgradeRegistry(ZERO_ADDRESS);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.upgradeRegistry(FAKE_CONTRACT);
    }

    function testSetIsOpened() public {
        vm.stopPrank();
        vm.prank(ADMIN);
        operator.setIsOpened(true);

        assertEq(true, auction.isOpened());
        assertEq(true, registry.isOpened());

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "operator"));
        auction.setIsOpened(true, ADMIN);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "operator"));
        registry.setIsOpened(true, ADMIN);
    }

    function testSetIsOpenedByAttacker() public {
        vm.stopPrank();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.setIsOpened(true);
    }

    //////////////////////////////
    /// Board
    //////////////////////////////

    function testMintBoard() public {
        vm.stopPrank();

        // mint
        vm.prank(ADMIN);
        operator.mintBoard(ADMIN);
        assertEq(1, registry.balanceOf(ADMIN));

        // get board & check data
        IBillboardRegistry.Board memory board = operator.getBoard(1);
        assertEq(ADMIN, board.owner);
        assertEq(ADMIN, board.tenant);
        assertEq(0, board.lastHighestBidPrice);
        assertEq("", board.name);
        assertEq("", board.description);
        assertEq("", board.location);
        assertEq("", board.contentURI);
        assertEq("", board.redirectLink);

        // set properties

        // get board & check data
    }

    function testMintBoardByAttacker() public {
        // mint
        // set properties
        // transfer
    }

    //////////////////////////////
    /// Auction
    //////////////////////////////

    function testBid() public {}

    function testClearAuction() public {}

    function testBidByAttacker() public {}

    function testClearAuctionByAttacker() public {}
}
