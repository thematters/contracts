//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./BillboardTestBase.t.sol";

contract BillboardTest is BillboardTestBase {
    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    function testUpgradeRegistry() public {
        vm.startPrank(ADMIN);

        // deploy new operator
        Billboard newOperator = new Billboard(address(registry), TAX_RATE, "BLBD", "BLBD");
        assertEq(newOperator.admin(), ADMIN);

        // upgrade registry's operator
        assertEq(registry.operator(), address(operator));
        operator.setRegistryOperator(address(newOperator));
        assertEq(registry.operator(), address(newOperator));
    }

    function testUpgradeRegistryByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.setRegistryOperator(FAKE_CONTRACT);
    }

    //////////////////////////////
    /// Access control
    //////////////////////////////

    function testSetIsOpened() public {
        vm.startPrank(ADMIN);

        operator.setIsOpened(true);
        assertEq(operator.isOpened(), true);

        operator.setIsOpened(false);
        assertEq(operator.isOpened(), false);
    }

    function testSetIsOpenedByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.setIsOpened(true);
    }

    function testAddToWhitelist() public {
        vm.startPrank(ADMIN);

        operator.addToWhitelist(USER_A);
        assertEq(operator.whitelist(USER_A), true);
        assertEq(operator.whitelist(USER_B), false);
    }

    function testAddToWhitelistByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.addToWhitelist(USER_A);
    }

    function testRemoveToWhitelist() public {
        vm.startPrank(ADMIN);

        operator.addToWhitelist(USER_A);
        assertEq(operator.whitelist(USER_A), true);

        operator.removeFromWhitelist(USER_A);
        assertEq(operator.whitelist(USER_A), false);
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
        assertEq(registry.balanceOf(ADMIN), 1);

        // ownership
        assertEq(registry.ownerOf(1), ADMIN);

        // get board & check data
        IBillboardRegistry.Board memory board = operator.getBoard(1);
        assertEq(board.creator, ADMIN);
        assertEq(board.auctionId, 0);
        assertEq(board.name, "");
        assertEq(board.description, "");
        assertEq(board.location, "");
        assertEq(board.contentURI, "");
        assertEq(board.redirectURI, "");

        // mint again for checking id generator
        operator.mintBoard(ADMIN);
        assertEq(registry.balanceOf(ADMIN), 2);
        board = operator.getBoard(2);
        assertEq(board.creator, ADMIN);
    }

    function testMintBoardIfOpened() public {
        vm.startPrank(ADMIN);
        operator.setIsOpened(true);

        vm.startPrank(USER_A);
        operator.mintBoard(USER_A);
        assertEq(registry.balanceOf(USER_A), 1);
    }

    function testMintBoardByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "whitelist"));
        operator.mintBoard(ATTACKER);
    }

    function testSetBoardProperties() public {
        uint256 _tokenId = _mintBoard(ADMIN);

        vm.startPrank(ADMIN);

        operator.setBoardName(_tokenId, "name");
        operator.setBoardDescription(_tokenId, "description");
        operator.setBoardLocation(_tokenId, "location");
        operator.setBoardContentURI(_tokenId, "uri");
        operator.setBoardRedirectURI(_tokenId, "redirect URI");

        IBillboardRegistry.Board memory board = operator.getBoard(1);
        assertEq(board.name, "name");
        assertEq(board.description, "description");
        assertEq(board.location, "location");
        assertEq(board.contentURI, "uri");
        assertEq(board.redirectURI, "redirect URI");
    }

    function testSetBoardProprtiesByAttacker() public {
        uint256 _tokenId = _mintBoard(ADMIN);

        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
        operator.setBoardName(_tokenId, "name");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
        operator.setBoardDescription(_tokenId, "description");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
        operator.setBoardLocation(_tokenId, "location");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "tenant"));
        operator.setBoardContentURI(_tokenId, "uri");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "tenant"));
        operator.setBoardRedirectURI(_tokenId, "redirect URI");
    }

    function testGetTokenURI() public {
        uint256 _tokenId = _mintBoard(ADMIN);

        vm.startPrank(ADMIN);

        operator.setBoardContentURI(_tokenId, "new uri");
        assertEq(registry.tokenURI(_tokenId), "new uri");
    }

    // function testTransfer() public {
    //     _mintBoard();

    //     vm.stopPrank();
    //     vm.startPrank(ADMIN);
    //     assertEq(ADMIN, registry.ownerOf(1));

    //     // transfer board from admin to zero address
    //     vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
    //     registry.transferFrom(ADMIN, ZERO_ADDRESS, 1);

    //     // transfer board from admin to user_a
    //     registry.transferFrom(ADMIN, USER_A, 1);
    //     IBillboardRegistry.Board memory board = operator.getBoard(1);
    //     assertEq(ADMIN, board.creator);
    //     assertEq(USER_A, board.tenant);
    //     assertEq(USER_A, registry.ownerOf(1));

    //     vm.stopPrank();
    //     vm.startPrank(USER_A);

    //     vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
    //     operator.setBoardName(1, "name by a");

    //     vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
    //     operator.setBoardDescription(1, "description by a");

    //     vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
    //     operator.setBoardLocation(1, "location by a");

    //     operator.setBoardContentURI(1, "uri by a");
    //     operator.setBoardRedirectURI(1, "redirect URI by a");

    //     board = operator.getBoard(1);
    //     assertEq("", board.name);
    //     assertEq("", board.description);
    //     assertEq("", board.location);
    //     assertEq("uri by a", board.contentURI);
    //     assertEq("redirect URI by a", board.redirectURI);

    //     // transfer board from user_a to user_b
    //     registry.safeTransferFrom(USER_A, USER_B, 1);
    //     board = operator.getBoard(1);
    //     assertEq(ADMIN, board.creator);
    //     assertEq(USER_B, board.tenant);
    //     assertEq(USER_B, registry.ownerOf(1));

    //     vm.stopPrank();
    //     vm.startPrank(USER_B);

    //     vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
    //     operator.setBoardName(1, "name by b");

    //     vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
    //     operator.setBoardDescription(1, "description by b");

    //     vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
    //     operator.setBoardLocation(1, "location by b");

    //     operator.setBoardContentURI(1, "uri by b");
    //     operator.setBoardRedirectURI(1, "redirect URI by b");

    //     board = operator.getBoard(1);
    //     assertEq("", board.name);
    //     assertEq("", board.description);
    //     assertEq("", board.location);
    //     assertEq("uri by b", board.contentURI);
    //     assertEq("redirect URI by b", board.redirectURI);

    //     // transfer board from user_b to user_c by operator
    //     vm.stopPrank();
    //     vm.startPrank(address(operator));

    //     registry.transferFrom(USER_B, USER_C, 1);
    //     board = operator.getBoard(1);
    //     assertEq(ADMIN, board.creator);
    //     assertEq(USER_C, board.tenant);
    //     assertEq(USER_C, registry.ownerOf(1));

    //     vm.stopPrank();
    //     vm.startPrank(USER_C);

    //     vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
    //     operator.setBoardName(1, "name by b");

    //     vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
    //     operator.setBoardDescription(1, "description by b");

    //     vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
    //     operator.setBoardLocation(1, "location by b");

    //     operator.setBoardContentURI(1, "uri by c");
    //     operator.setBoardRedirectURI(1, "redirect URI by c");

    //     board = operator.getBoard(1);
    //     assertEq("", board.name);
    //     assertEq("", board.description);
    //     assertEq("", board.location);
    //     assertEq("uri by c", board.contentURI);
    //     assertEq("redirect URI by c", board.redirectURI);
    // }

    // function testTransferByAttacker() public {
    //     _mintBoard();

    //     vm.stopPrank();
    //     vm.startPrank(ATTACKER);

    //     vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "not owner nor approved"));
    //     registry.transferFrom(ADMIN, ATTACKER, 1);

    //     vm.stopPrank();
    //     vm.startPrank(ADMIN);
    //     registry.transferFrom(ADMIN, USER_A, 1);

    //     vm.stopPrank();
    //     vm.startPrank(ATTACKER);

    //     vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "not owner nor approved"));
    //     registry.safeTransferFrom(USER_A, ATTACKER, 1);
    // }

    // function testApprove() public {
    //     _mintBoard();

    //     vm.stopPrank();
    //     vm.startPrank(ADMIN);

    //     registry.approve(USER_A, 1);
    //     assertEq(USER_A, registry.getApproved(1));

    //     vm.stopPrank();
    //     vm.startPrank(USER_A);
    //     registry.transferFrom(ADMIN, USER_A, 1);

    //     IBillboardRegistry.Board memory board = operator.getBoard(1);
    //     assertEq(ADMIN, board.creator);
    //     assertEq(USER_A, board.tenant);
    // }

    // function testApproveByAttacker() public {
    //     _mintBoard();

    //     vm.stopPrank();
    //     vm.startPrank(USER_A);

    //     vm.expectRevert("ERC721: approve caller is not token owner or approved for all");
    //     registry.approve(USER_A, 1);
    // }

    // //////////////////////////////
    // /// Auction
    // //////////////////////////////

    // function testSetTaxRate() public {
    //     vm.startPrank(ADMIN);

    //     operator.setTaxRate(2);
    //     assertEq(2, operator.getTaxRate());
    // }

    // function testSetTaxRateByAttacker() public {
    //     vm.startPrank(ATTACKER);

    //     vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
    //     operator.setTaxRate(2);
    // }

    // function testBid() public {}

    // function testClearAuction() public {}

    // function testBidByAttacker() public {}

    // function testClearAuctionByAttacker() public {}
}
