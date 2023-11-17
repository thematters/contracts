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
        Billboard newOperator = new Billboard(payable(registry), TAX_RATE, "BLBD", "BLBD");
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

    function testCannotSetIsOpenedByAttacker() public {
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

    function testCannotAddToWhitelistByAttacker() public {
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

    function testCannotRemoveToWhitelistByAttacker() public {
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

    function testMintBoardByWhitelist() public {
        vm.prank(USER_A);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "whitelist"));
        operator.mintBoard(USER_A);

        vm.prank(ADMIN);
        operator.addToWhitelist(USER_A);

        vm.prank(USER_A);
        operator.mintBoard(USER_A);
        assertEq(registry.balanceOf(USER_A), 1);
    }

    function testCannotMintBoardByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "whitelist"));
        operator.mintBoard(ATTACKER);
    }

    function testSetBoardProperties() public {
        uint256 _tokenId = _mintBoard();

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

    function testCannotSetBoardProprtiesByAttacker() public {
        uint256 _tokenId = _mintBoard();

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
        uint256 _tokenId = _mintBoard();

        vm.startPrank(ADMIN);

        operator.setBoardContentURI(_tokenId, "new uri");
        assertEq(registry.tokenURI(_tokenId), "new uri");
    }

    function testTransfer() public {
        // mint
        uint256 _tokenId = _mintBoard();

        // transfer
        vm.startPrank(ADMIN);
        registry.transferFrom(ADMIN, USER_A, _tokenId);

        IBillboardRegistry.Board memory board = operator.getBoard(_tokenId);
        assertEq(board.creator, ADMIN);
        assertEq(registry.balanceOf(ADMIN), 0);
        assertEq(registry.ownerOf(_tokenId), USER_A);

        // set board properties
        vm.stopPrank();
        vm.startPrank(USER_A);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
        operator.setBoardName(_tokenId, "name by a");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
        operator.setBoardDescription(_tokenId, "description by a");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
        operator.setBoardLocation(_tokenId, "location by a");

        operator.setBoardContentURI(_tokenId, "uri by a");
        operator.setBoardRedirectURI(_tokenId, "redirect URI by a");

        board = operator.getBoard(_tokenId);
        assertEq(board.name, "");
        assertEq(board.description, "");
        assertEq(board.location, "");
        assertEq(board.contentURI, "uri by a");
        assertEq(board.redirectURI, "redirect URI by a");

        // transfer board from user_a to user_b
        registry.safeTransferFrom(USER_A, USER_B, 1);
        board = operator.getBoard(_tokenId);
        assertEq(board.creator, ADMIN);
        assertEq(registry.ownerOf(_tokenId), USER_B);

        vm.stopPrank();
        vm.startPrank(USER_B);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
        operator.setBoardName(_tokenId, "name by b");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
        operator.setBoardDescription(_tokenId, "description by b");

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "creator"));
        operator.setBoardLocation(_tokenId, "location by b");

        operator.setBoardContentURI(_tokenId, "uri by b");
        operator.setBoardRedirectURI(_tokenId, "redirect URI by b");

        board = operator.getBoard(_tokenId);
        assertEq(board.name, "");
        assertEq(board.description, "");
        assertEq(board.location, "");
        assertEq(board.contentURI, "uri by b");
        assertEq(board.redirectURI, "redirect URI by b");
    }

    function testCannotTransferToZeroAddress() public {
        uint256 _tokenId = _mintBoard();

        vm.startPrank(ADMIN);

        vm.expectRevert("ERC721: transfer to the zero address");
        registry.transferFrom(ADMIN, ZERO_ADDRESS, _tokenId);
    }

    function testCannotTransferByOperator() public {
        uint256 _tokenId = _mintBoard();

        vm.startPrank(address(operator));

        vm.expectRevert("ERC721: caller is not token owner or approved");
        registry.transferFrom(USER_B, USER_C, _tokenId);
    }

    function testTransferByOperator() public {
        uint256 _tokenId = _mintBoard();

        vm.startPrank(address(operator));
        registry.safeTransferByOperator(ADMIN, USER_A, _tokenId);
        assertEq(registry.ownerOf(_tokenId), USER_A);
    }

    function testCannotTransferByAttacker() public {
        uint256 _tokenId = _mintBoard();

        vm.startPrank(ATTACKER);

        vm.expectRevert("ERC721: caller is not token owner or approved");
        registry.transferFrom(ADMIN, ATTACKER, _tokenId);
    }

    function testApprove() public {
        uint256 _tokenId = _mintBoard();

        vm.startPrank(ADMIN);
        registry.approve(USER_A, _tokenId);
        assertEq(registry.getApproved(_tokenId), USER_A);

        vm.stopPrank();
        vm.startPrank(USER_A);
        registry.transferFrom(ADMIN, USER_A, _tokenId);

        IBillboardRegistry.Board memory board = operator.getBoard(_tokenId);
        assertEq(board.creator, ADMIN);
    }

    function testCannotApproveByAttacker() public {
        uint256 _tokenId = _mintBoard();

        vm.stopPrank();
        vm.startPrank(ATTACKER);
        vm.expectRevert("ERC721: approve caller is not token owner or approved for all");
        registry.approve(USER_A, _tokenId);
    }

    //////////////////////////////
    /// Auction
    //////////////////////////////

    function testPlaceBidOnNewBoard() public {
        vm.prank(ADMIN);
        operator.addToWhitelist(USER_A);

        uint256 _tokenId = _mintBoard();
        uint256 _amount = 1 ether;
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;
        vm.deal(USER_A, _total);

        uint256 _prevNextActionId = registry.nextBoardAuctionId(_tokenId);
        uint256 _prevCreatorBalance = ADMIN.balance;
        uint256 _prevBidderBalance = USER_A.balance;
        uint256 _prevOperatorBalance = address(operator).balance;
        uint256 _prevRegistryBalance = address(registry).balance;

        vm.prank(USER_A);
        operator.placeBid{value: _total}(_tokenId, _amount);

        // check balances
        assertEq(ADMIN.balance, _prevCreatorBalance + _amount);
        assertEq(USER_A.balance, _prevBidderBalance - _total);
        assertEq(address(operator).balance, _prevOperatorBalance);
        assertEq(address(registry).balance, _prevRegistryBalance + _tax);

        // check auction
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_prevNextActionId, 0);
        assertEq(_nextAuctionId, _prevNextActionId + 1);
        assertEq(_auction.startAt, block.timestamp);
        assertEq(_auction.endAt, block.timestamp);
        assertEq(_auction.leaseStartAt, block.timestamp);
        assertEq(_auction.leaseEndAt, block.timestamp + registry.leaseTerm());
        assertEq(_auction.highestBidder, USER_A);

        // check bid
        IBillboardRegistry.Bid memory _bid = registry.getBid(_tokenId, _nextAuctionId, USER_A);
        assertEq(_bid.price, _amount);
        assertEq(_bid.tax, _tax);
        assertEq(_bid.placedAt, block.timestamp);
        assertEq(_bid.isWon, true);
        assertEq(_bid.isWithdrawn, false);
    }

    function testPlaceBidWithSamePrice() public {
        (uint256 _tokenId, uint256 _prevNextAuctionId) = _mintBoardAndPlaceBid();
        uint256 _amount = 1 ether;
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // new auction and new bid with USER_A
        vm.deal(USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid{value: _total}(_tokenId, _amount);
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        assertEq(_nextAuctionId, _prevNextAuctionId + 1);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_A);

        // new bid with USER_B
        vm.deal(USER_B, _total);
        vm.prank(USER_B);
        operator.placeBid{value: _total}(_tokenId, _amount);
        _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        assertEq(_nextAuctionId, _prevNextAuctionId + 1); // still the same auction
        _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_A); // USER_A is still the same highest bidder

        // check if bids exist
        IBillboardRegistry.Bid memory _bidA = registry.getBid(_tokenId, _nextAuctionId, USER_A);
        assertEq(_bidA.placedAt, block.timestamp);
        assertEq(_bidA.isWon, false);
        IBillboardRegistry.Bid memory _bidB = registry.getBid(_tokenId, _nextAuctionId, USER_A);
        assertEq(_bidB.placedAt, block.timestamp);
        assertEq(_bidB.isWon, false);

        // check registry balance
        assertEq(address(registry).balance, _total * 2);
    }

    function testPlaceBidWithHigherPrice() public {
        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _amount = 1 ether;
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // bid with USER_A
        vm.deal(USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid{value: _total}(_tokenId, _amount);
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_A);

        // bid with USER_B
        vm.startPrank(USER_B);
        vm.deal(USER_B, _total * 2);
        operator.placeBid{value: _total * 2}(_tokenId, _amount * 2);
        _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_B);
    }

    function testPlaceBidZeroPrice() public {
        uint256 _tokenId = _mintBoard();

        vm.startPrank(ADMIN);
        vm.deal(ADMIN, 1 ether);
        uint256 _prevBalance = ADMIN.balance;

        operator.placeBid{value: 0}(_tokenId, 0);

        // check balances
        uint256 _afterBalance = ADMIN.balance;
        assertEq(_afterBalance, _prevBalance);
        assertEq(address(operator).balance, 0);
        assertEq(address(registry).balance, 0);

        // check auction
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, ADMIN);

        // check bid
        IBillboardRegistry.Bid memory _bid = registry.getBid(_tokenId, _nextAuctionId, ADMIN);
        assertEq(_bid.placedAt, block.timestamp);
        assertEq(_bid.isWon, true);
    }

    function testPlaceBidByWhitelist() public {
        uint256 _tokenId = _mintBoard();
        uint256 _amount = 1 ether;
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        vm.prank(ADMIN);
        operator.addToWhitelist(USER_A);

        vm.deal(USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid{value: _total}(_tokenId, _amount);
        assertEq(USER_A.balance, 0);
    }

    function testPlaceBidIfAuctionEnded() public {
        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _amount = 1 ether;
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // place a bid with USER_A
        vm.startPrank(USER_A);
        vm.deal(USER_A, _total);
        operator.placeBid{value: _total}(_tokenId, _amount);

        // check auction
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_A);
        assertEq(_auction.endAt, block.timestamp + registry.leaseTerm());

        // make auction ended
        vm.warp(_auction.endAt + 1 seconds);

        // place a bid with USER_B
        vm.startPrank(USER_B);
        vm.deal(USER_B, _total);
        operator.placeBid{value: _total}(_tokenId, _amount);

        // check auction
        uint256 _newNextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _newAuction = registry.getAuction(_tokenId, _newNextAuctionId);
        assertEq(_newNextAuctionId, _nextAuctionId + 1);
        assertEq(_newAuction.highestBidder, USER_B);
        assertEq(_newAuction.endAt, block.timestamp + registry.leaseTerm());

        // USER_A won the previous auction
        IBillboardRegistry.Bid memory _bid = registry.getBid(_tokenId, _nextAuctionId, USER_A);
        assertEq(_bid.isWon, true);

        // USER_B's bid is still in a running auction
        IBillboardRegistry.Bid memory _newBid = registry.getBid(_tokenId, _newNextAuctionId, USER_B);
        assertEq(_newBid.isWon, false);
    }

    function testCannotPlaceBidTwice() public {
        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _amount = 1 ether;
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        vm.startPrank(USER_A);
        vm.deal(USER_A, _total);
        operator.placeBid{value: _total}(_tokenId, _amount);
        assertEq(USER_A.balance, 0);

        vm.deal(USER_A, _total);
        vm.expectRevert(abi.encodeWithSignature("BidAlreadyPlaced()"));
        operator.placeBid{value: _total}(_tokenId, _amount);
    }

    function testCannotPlaceBidByAttacker() public {
        uint256 _tokenId = _mintBoard();
        uint256 _amount = 1 ether;
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        vm.startPrank(ATTACKER);
        vm.deal(ATTACKER, _total);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "whitelist"));
        operator.placeBid{value: _total}(_tokenId, _amount);
    }

    function testCannotClearAuctionOnNewBoard() public {
        uint256 _mintedAt = block.timestamp;
        uint256 _clearedAt = _mintedAt + 1;
        uint256 _tokenId = _mintBoard();

        vm.startPrank(ADMIN);

        // clear auction
        vm.warp(_clearedAt);
        vm.expectRevert(abi.encodeWithSignature("AuctionNotFound()"));
        operator.clearAuction(_tokenId);
    }

    function testCannotClearAuctionIfAuctionNotEnded() public {
        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();

        // place a bid
        vm.startPrank(USER_A);
        vm.deal(USER_A, 0);
        operator.placeBid{value: 0}(_tokenId, 0);

        // try to clear auction
        vm.expectRevert(abi.encodeWithSignature("AuctionNotEnded()"));
        operator.clearAuction(_tokenId);

        vm.warp(block.timestamp + registry.leaseTerm() - 1 seconds);
        vm.expectRevert(abi.encodeWithSignature("AuctionNotEnded()"));
        operator.clearAuction(_tokenId);
    }

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

    function testSetTaxRate() public {
        vm.startPrank(ADMIN);

        operator.setTaxRate(2);
        assertEq(operator.getTaxRate(), 2);
    }

    function testCannotSetTaxRateByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.setTaxRate(2);
    }

    function testWithdrawTax() public {}

    function testCannotWithdrawTaxByAttacker() public {}

    function testWithdrawBid() public {}

    function testCannotWithdrawBidByAttacker() public {}
}
