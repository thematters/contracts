//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./BillboardTestBase.t.sol";

contract BillboardTest is BillboardTestBase {
    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    function testUpgradeAuctionByAttacker() public {
        vm.stopPrank();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        operator.upgradeAuction(ZERO_ADDRESS);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.upgradeAuction(FAKE_CONTRACT);
    }

    function testUpgradeRegistryByAttacker() public {
        vm.stopPrank();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        operator.upgradeRegistry(ZERO_ADDRESS);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.upgradeRegistry(FAKE_CONTRACT);
    }

    function testSetIsOpened() public {
        vm.stopPrank();
        vm.startPrank(ADMIN);
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
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.setIsOpened(true);
    }

    //////////////////////////////
    /// Board
    //////////////////////////////

    function testMintBoard() public {
        vm.stopPrank();
        vm.startPrank(ADMIN);

        // mint
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
    }

    function testMintBoardByAttacker() public {
        vm.stopPrank();
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "minter"));
        operator.mintBoard(ATTACKER);
    }

    function testSetBoardProperties() public {
        _mintBoard();

        vm.stopPrank();
        vm.startPrank(ADMIN);

        operator.setBoardName(1, "name");
        operator.setBoardDescription(1, "description");
        operator.setBoardLocation(1, "location");
        operator.setBoardContentURI(1, "contentURI");
        operator.setBoardRedirectLink(1, "redirect link");

        IBillboardRegistry.Board memory board = operator.getBoard(1);
        assertEq("name", board.name);
        assertEq("description", board.description);
        assertEq("location", board.location);
        assertEq("contentURI", board.contentURI);
        assertEq("redirect link", board.redirectLink);
    }

    function testSetBoardProprtiesByAttacker() public {
        _mintBoard();

        vm.stopPrank();
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board owner"));
        operator.setBoardName(1, "name");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board owner"));
        operator.setBoardDescription(1, "description");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board owner"));
        operator.setBoardLocation(1, "location");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board tenant"));
        operator.setBoardContentURI(1, "contentURI");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board tenant"));
        operator.setBoardRedirectLink(1, "redirect link");
    }

    //////////////////////////////
    /// Auction
    //////////////////////////////

    function testBid() public {}

    function testClearAuction() public {}

    function testBidByAttacker() public {}

    function testClearAuctionByAttacker() public {}
}
