//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./BillboardTestBase.t.sol";

contract BillboardTest is BillboardTestBase {
    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    function testUpgradeAuctionByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        operator.upgradeAuction(ZERO_ADDRESS);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.upgradeAuction(FAKE_CONTRACT);
    }

    function testUpgradeRegistryByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        operator.upgradeRegistry(ZERO_ADDRESS);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.upgradeRegistry(FAKE_CONTRACT);
    }

    function testSetIsOpened() public {
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
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.setIsOpened(true);
    }

    function testAddToWhitelist() public {
        vm.startPrank(ADMIN);

        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        operator.addToWhitelist(ZERO_ADDRESS);

        operator.addToWhitelist(USER_A);
        assertEq(registry.whitelist(USER_A), true);
        assertEq(registry.whitelist(USER_B), false);
        assertEq(auction.whitelist(USER_A), true);
        assertEq(auction.whitelist(USER_B), false);

        // not allow bypassing operator
        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "operator"));
        registry.addToWhitelist(USER_A, ADMIN);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "operator"));
        auction.addToWhitelist(USER_A, ADMIN);
    }

    function testAddToWhitelistByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.addToWhitelist(USER_A);
    }

    function testRemoveToWhitelist() public {
        vm.startPrank(ADMIN);

        operator.addToWhitelist(USER_A);
        assertEq(registry.whitelist(USER_A), true);

        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        operator.removeFromWhitelist(ZERO_ADDRESS);

        operator.removeFromWhitelist(USER_A);
        assertEq(registry.whitelist(USER_A), false);
        assertEq(auction.whitelist(USER_A), false);

        // not allow bypassing operator
        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "operator"));
        registry.removeFromWhitelist(USER_A, ADMIN);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "operator"));
        auction.removeFromWhitelist(USER_A, ADMIN);
    }

    function testRemoveToWhitelistByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.removeFromWhitelist(USER_B);
    }

    //////////////////////////////
    /// Board
    //////////////////////////////

    function testMintBoard() public {
        vm.startPrank(ADMIN);

        // mint
        operator.mintBoard(ADMIN);
        assertEq(1, registry.balanceOf(ADMIN));

        // get board & check data
        IBillboardRegistry.Board memory board = operator.getBoard(1);
        assertEq(ADMIN, board.creator);
        assertEq(ADMIN, board.tenant);
        assertEq(0, board.lastHighestBidPrice);
        assertEq("", board.name);
        assertEq("", board.description);
        assertEq("", board.location);
        assertEq("", board.contentURI);
        assertEq("", board.redirectURI);

        // mint again for checking id generator
        operator.mintBoard(ADMIN);
        assertEq(2, registry.balanceOf(ADMIN));
        board = operator.getBoard(2);
        assertEq(ADMIN, board.creator);
        assertEq(ADMIN, board.tenant);
    }

    function testMintBoardByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
        operator.mintBoard(ATTACKER);
    }

    function testSetBoardProperties() public {
        _mintBoard();

        vm.stopPrank();
        vm.startPrank(ADMIN);

        operator.setBoardName(1, "name");
        operator.setBoardDescription(1, "description");
        operator.setBoardLocation(1, "location");
        operator.setBoardContentURI(1, "uri");
        operator.setBoardRedirectURI(1, "redirect URI");

        IBillboardRegistry.Board memory board = operator.getBoard(1);
        assertEq("name", board.name);
        assertEq("description", board.description);
        assertEq("location", board.location);
        assertEq("uri", board.contentURI);
        assertEq("redirect URI", board.redirectURI);
    }

    function testSetBoardProprtiesByAttacker() public {
        _mintBoard();

        vm.stopPrank();
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board creator"));
        operator.setBoardName(1, "name");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board creator"));
        operator.setBoardDescription(1, "description");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board creator"));
        operator.setBoardLocation(1, "location");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board tenant"));
        operator.setBoardContentURI(1, "uri");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board tenant"));
        operator.setBoardRedirectURI(1, "redirect URI");
    }

    function testGetTokenURI() public {
        _mintBoard();

        vm.stopPrank();
        vm.startPrank(ADMIN);

        operator.setBoardContentURI(1, "new uri");
        assertEq("new uri", registry.tokenURI(1));
    }

    function testTransfer() public {
        _mintBoard();

        vm.stopPrank();
        vm.startPrank(ADMIN);
        assertEq(ADMIN, registry.ownerOf(1));

        // transfer board from admin to zero address
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        registry.transferFrom(ADMIN, ZERO_ADDRESS, 1);

        // transfer board from admin to user_a
        registry.transferFrom(ADMIN, USER_A, 1);
        IBillboardRegistry.Board memory board = operator.getBoard(1);
        assertEq(ADMIN, board.creator);
        assertEq(USER_A, board.tenant);
        assertEq(USER_A, registry.ownerOf(1));

        vm.stopPrank();
        vm.startPrank(USER_A);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board creator"));
        operator.setBoardName(1, "name by a");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board creator"));
        operator.setBoardDescription(1, "description by a");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board creator"));
        operator.setBoardLocation(1, "location by a");

        operator.setBoardContentURI(1, "uri by a");
        operator.setBoardRedirectURI(1, "redirect URI by a");

        board = operator.getBoard(1);
        assertEq("", board.name);
        assertEq("", board.description);
        assertEq("", board.location);
        assertEq("uri by a", board.contentURI);
        assertEq("redirect URI by a", board.redirectURI);

        // transfer board from user_a to user_b
        registry.safeTransferFrom(USER_A, USER_B, 1);
        board = operator.getBoard(1);
        assertEq(ADMIN, board.creator);
        assertEq(USER_B, board.tenant);
        assertEq(USER_B, registry.ownerOf(1));

        vm.stopPrank();
        vm.startPrank(USER_B);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board creator"));
        operator.setBoardName(1, "name by b");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board creator"));
        operator.setBoardDescription(1, "description by b");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board creator"));
        operator.setBoardLocation(1, "location by b");

        operator.setBoardContentURI(1, "uri by b");
        operator.setBoardRedirectURI(1, "redirect URI by b");

        board = operator.getBoard(1);
        assertEq("", board.name);
        assertEq("", board.description);
        assertEq("", board.location);
        assertEq("uri by b", board.contentURI);
        assertEq("redirect URI by b", board.redirectURI);

        // transfer board from user_b to user_c by operator
        vm.stopPrank();
        vm.startPrank(address(operator));

        registry.transferFrom(USER_B, USER_C, 1);
        board = operator.getBoard(1);
        assertEq(ADMIN, board.creator);
        assertEq(USER_C, board.tenant);
        assertEq(USER_C, registry.ownerOf(1));

        vm.stopPrank();
        vm.startPrank(USER_C);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board creator"));
        operator.setBoardName(1, "name by b");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board creator"));
        operator.setBoardDescription(1, "description by b");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "board creator"));
        operator.setBoardLocation(1, "location by b");

        operator.setBoardContentURI(1, "uri by c");
        operator.setBoardRedirectURI(1, "redirect URI by c");

        board = operator.getBoard(1);
        assertEq("", board.name);
        assertEq("", board.description);
        assertEq("", board.location);
        assertEq("uri by c", board.contentURI);
        assertEq("redirect URI by c", board.redirectURI);
    }

    function testTransferByAttacker() public {
        _mintBoard();

        vm.stopPrank();
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "not owner nor approved"));
        registry.transferFrom(ADMIN, ATTACKER, 1);

        vm.stopPrank();
        vm.startPrank(ADMIN);
        registry.transferFrom(ADMIN, USER_A, 1);

        vm.stopPrank();
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "not owner nor approved"));
        registry.safeTransferFrom(USER_A, ATTACKER, 1);
    }

    function testApprove() public {
        _mintBoard();

        vm.stopPrank();
        vm.startPrank(ADMIN);

        registry.approve(USER_A, 1);
        assertEq(USER_A, registry.getApproved(1));

        vm.stopPrank();
        vm.startPrank(USER_A);
        registry.transferFrom(ADMIN, USER_A, 1);

        IBillboardRegistry.Board memory board = operator.getBoard(1);
        assertEq(ADMIN, board.creator);
        assertEq(USER_A, board.tenant);
    }

    function testApproveByAttacker() public {
        _mintBoard();

        vm.stopPrank();
        vm.startPrank(USER_A);

        vm.expectRevert("ERC721: approve caller is not token owner or approved for all");
        registry.approve(USER_A, 1);
    }

    //////////////////////////////
    /// Auction
    //////////////////////////////

    function testSetTaxRate() public {
        vm.startPrank(ADMIN);

        operator.setTaxRate(2);
        assertEq(2, operator.getTaxRate());
    }

    function testSetTaxRateByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.setTaxRate(2);
    }

    function testBid() public {}

    function testClearAuction() public {}

    function testBidByAttacker() public {}

    function testClearAuctionByAttacker() public {}
}
