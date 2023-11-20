//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./BillboardTestBase.t.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BillboardTest is BillboardTestBase {
    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    function testUpgradeRegistry() public {
        vm.startPrank(ADMIN);

        // deploy new operator
        Billboard newOperator = new Billboard(payable(registry), TAX_RATE, "Billboard2", "BLBD2");
        assertEq(newOperator.admin(), ADMIN);
        assertEq(registry.name(), "Billboard"); // registry is not changed
        assertEq(registry.symbol(), "BLBD"); // registry is not changed

        // upgrade registry's operator
        assertEq(registry.operator(), address(operator));
        operator.setRegistryOperator(address(newOperator));
        assertEq(registry.operator(), address(newOperator));
    }

    function testCannotUpgradeRegistryByAttacker() public {
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
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), ADMIN, 1);
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
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), ADMIN, 2);
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

        vm.expectEmit(true, true, false, false);
        emit IBillboardRegistry.BoardNameUpdated(_tokenId, "name");
        operator.setBoardName(_tokenId, "name");

        vm.expectEmit(true, true, false, false);
        emit IBillboardRegistry.BoardDescriptionUpdated(_tokenId, "description");
        operator.setBoardDescription(_tokenId, "description");

        vm.expectEmit(true, true, false, false);
        emit IBillboardRegistry.BoardLocationUpdated(_tokenId, "location");
        operator.setBoardLocation(_tokenId, "location");

        vm.expectEmit(true, true, false, false);
        emit IBillboardRegistry.BoardContentURIUpdated(_tokenId, "uri");
        operator.setBoardContentURI(_tokenId, "uri");

        vm.expectEmit(true, true, false, false);
        emit IBillboardRegistry.BoardRedirectURIUpdated(_tokenId, "redirect URI");
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

    function testSetBoardPropertiesAfterTransfer() public {
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

    function testSafeTransferByOperator() public {
        uint256 _tokenId = _mintBoard();

        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(ADMIN, USER_A, _tokenId);

        vm.startPrank(address(operator));
        registry.safeTransferByOperator(ADMIN, USER_A, _tokenId);
        assertEq(registry.ownerOf(_tokenId), USER_A);
    }

    function testCannotSafeTransferByAttacker() public {
        uint256 _tokenId = _mintBoard();

        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "operator"));
        registry.safeTransferByOperator(ADMIN, ATTACKER, _tokenId);
    }

    function testApproveAndTransfer() public {
        uint256 _tokenId = _mintBoard();

        vm.expectEmit(true, true, true, true);
        emit IERC721.Approval(ADMIN, USER_A, _tokenId);
        vm.prank(ADMIN);
        registry.approve(USER_A, _tokenId);
        assertEq(registry.getApproved(_tokenId), USER_A);

        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(ADMIN, USER_A, _tokenId);
        vm.prank(USER_A);
        registry.transferFrom(ADMIN, USER_A, _tokenId);

        IBillboardRegistry.Board memory board = operator.getBoard(_tokenId);
        assertEq(board.creator, ADMIN);
        assertEq(registry.ownerOf(_tokenId), USER_A);
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

    function testPlaceBidOnNewBoard(uint96 _amount) public {
        vm.prank(ADMIN);
        operator.addToWhitelist(USER_A);

        vm.expectEmit(true, false, false, false);
        emit IERC721.Transfer(address(0), ADMIN, 1);

        uint256 _tokenId = _mintBoard();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;
        vm.deal(USER_A, _total);

        uint256 _prevNextActionId = registry.nextBoardAuctionId(_tokenId);
        uint256 _prevCreatorBalance = ADMIN.balance;
        uint256 _prevBidderBalance = USER_A.balance;
        uint256 _prevOperatorBalance = address(operator).balance;
        uint256 _prevRegistryBalance = address(registry).balance;

        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.AuctionCreated(_tokenId, _prevNextActionId + 1, block.timestamp, block.timestamp);
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.BidCreated(_tokenId, _prevNextActionId + 1, USER_A, _amount, _tax);
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.BidWon(_tokenId, _prevNextActionId + 1, USER_A);
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.AuctionCleared(
            _tokenId,
            _prevNextActionId + 1,
            USER_A,
            block.timestamp,
            block.timestamp + registry.leaseTerm()
        );

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

    function testPlaceBidWithSamePrices(uint96 _amount) public {
        (uint256 _tokenId, uint256 _prevNextAuctionId) = _mintBoardAndPlaceBid();
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

    function testPlaceBidWithHigherPrice(uint96 _amount) public {
        vm.assume(_amount > 0);
        vm.assume(_amount < type(uint96).max / 2);

        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
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
        _amount = _amount * 2;
        _tax = operator.calculateTax(_amount);
        _total = _amount + _tax;
        vm.deal(USER_B, _total);
        vm.startPrank(USER_B);
        operator.placeBid{value: _total}(_tokenId, _amount);
        _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_B);
    }

    function testPlaceBidZeroPrice() public {
        uint256 _tokenId = _mintBoard();

        vm.startPrank(ADMIN);
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

    function testCannotPlaceBidTwice(uint96 _amount) public {
        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
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

    function testClearAuctionIfAuctionEnded() public {
        (uint256 _tokenId, uint256 _prevAuctionId) = _mintBoardAndPlaceBid();
        uint256 _placedAt = block.timestamp;
        uint256 _clearedAt = block.timestamp + registry.leaseTerm() + 1 minutes;

        // place a bid
        vm.startPrank(USER_A);
        vm.deal(USER_A, 0);
        operator.placeBid{value: 0}(_tokenId, 0);

        // clear auction
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.AuctionCleared(
            _tokenId,
            _prevAuctionId + 1,
            USER_A,
            _clearedAt,
            _clearedAt + registry.leaseTerm()
        );

        vm.warp(_clearedAt);
        operator.clearAuction(_tokenId);

        // check auction
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.startAt, _placedAt);
        assertEq(_auction.endAt, _placedAt + registry.leaseTerm());
        assertEq(_auction.leaseStartAt, _clearedAt);
        assertEq(_auction.leaseEndAt, _clearedAt + registry.leaseTerm());
        assertEq(_auction.highestBidder, USER_A);

        // check bid
        IBillboardRegistry.Bid memory _bid = registry.getBid(_tokenId, _nextAuctionId, USER_A);
        assertEq(_bid.price, 0);
        assertEq(_bid.tax, 0);
        assertEq(_bid.placedAt, _placedAt);
        assertEq(_bid.isWon, true);
        assertEq(_bid.isWithdrawn, false);
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

    function testGetBids(uint8 _bidCount, uint8 _limit, uint8 _offset) public {
        vm.assume(_bidCount > 0);
        vm.assume(_bidCount <= 64);
        vm.assume(_limit <= _bidCount);
        vm.assume(_offset <= _limit);

        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();

        for (uint8 i = 0; i < _bidCount; i++) {
            address _bidder = address(uint160(2000 + i));

            vm.prank(ADMIN);
            operator.addToWhitelist(_bidder);

            uint256 _amount = 1 ether + i;
            uint256 _tax = operator.calculateTax(_amount);
            uint256 _totalAmount = _amount + _tax;

            vm.deal(_bidder, _totalAmount);
            vm.prank(_bidder);
            operator.placeBid{value: _totalAmount}(_tokenId, _amount);
        }

        // get bids
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        console.log(_nextAuctionId);
        (uint256 _t, uint256 _l, uint256 _o, IBillboardRegistry.Bid[] memory _bids) = operator.getBids(
            _tokenId,
            _nextAuctionId,
            _limit,
            _offset
        );
        uint256 _left = _t - _offset;
        uint256 _size = _left > _limit ? _limit : _left;
        assertEq(_t, _bidCount);
        assertEq(_l, _limit);
        assertEq(_bids.length, _size);
        assertEq(_o, _offset);
        for (uint256 i = 0; i < _size; i++) {
            uint256 _amount = 1 ether + _offset + i;
            assertEq(_bids[i].price, _amount);
        }
    }

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

    function testCalculateTax() public {
        uint256 _amount = 100;
        uint256 _taxRate = 10; // 10% per day

        vm.startPrank(ADMIN);
        operator.setTaxRate(_taxRate);

        uint256 _tax = operator.calculateTax(_amount);
        assertEq(_tax, (_amount * _taxRate * 14) / 100);
    }

    function testSetTaxRate() public {
        vm.startPrank(ADMIN);

        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.TaxRateUpdated(2);

        operator.setTaxRate(2);
        assertEq(operator.getTaxRate(), 2);
    }

    function testCannotSetTaxRateByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("Unauthorized(string)", "admin"));
        operator.setTaxRate(2);
    }

    function testWithdrawTax(uint96 _amount) public {
        vm.assume(_amount > 0.001 ether);

        uint256 _tokenId = _mintBoard();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        vm.prank(ADMIN);
        operator.addToWhitelist(USER_A);

        // place a bid and win auction
        vm.deal(USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid{value: _total}(_tokenId, _amount);

        uint256 _prevRegistryBalance = address(registry).balance;
        uint256 _prevAdminBalance = ADMIN.balance;

        // withdraw tax
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.TaxWithdrawn(ADMIN, _tax);

        vm.prank(ADMIN);
        operator.withdrawTax();

        // check balances
        assertEq(address(registry).balance, _prevRegistryBalance - _tax);
        assertEq(ADMIN.balance, _prevAdminBalance + _tax);
    }

    function testCannnotWithdrawTaxIfZero() public {
        uint256 _tokenId = _mintBoard();

        vm.prank(ADMIN);
        operator.addToWhitelist(USER_A);

        // place a bid and win auction
        vm.deal(USER_A, 0);
        vm.prank(USER_A);
        operator.placeBid{value: 0}(_tokenId, 0);

        vm.prank(ADMIN);
        vm.expectRevert(abi.encodeWithSignature("WithdrawFailed(string)", "zero amount"));
        operator.withdrawTax();
    }

    function testCannnotWithdrawTaxIfSmallAmount(uint8 _amount) public {
        uint256 _tax = operator.calculateTax(_amount);
        vm.assume(_tax <= 0);

        uint256 _tokenId = _mintBoard();

        vm.prank(ADMIN);
        operator.addToWhitelist(USER_A);

        // place a bid and win auction
        vm.deal(USER_A, _amount);
        vm.prank(USER_A);
        operator.placeBid{value: _amount}(_tokenId, _amount);

        vm.prank(ADMIN);
        vm.expectRevert(abi.encodeWithSignature("WithdrawFailed(string)", "zero amount"));
        operator.withdrawTax();
    }

    function testCannotWithdrawTaxByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert(abi.encodeWithSignature("WithdrawFailed(string)", "zero amount"));
        operator.withdrawTax();
    }

    function testWithdrawBid(uint96 _amount) public {
        vm.assume(_amount > 0.001 ether);

        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // new auction and new bid with USER_A
        vm.deal(USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid{value: _total}(_tokenId, _amount);

        // new bid with USER_B
        vm.deal(USER_B, _total);
        vm.prank(USER_B);
        operator.placeBid{value: _total}(_tokenId, _amount);

        // clear auction
        vm.warp(block.timestamp + registry.leaseTerm() + 1 minutes);
        operator.clearAuction(_tokenId);

        // check auction
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_A);

        // check bid
        IBillboardRegistry.Bid memory _bidA = registry.getBid(_tokenId, _nextAuctionId, USER_A);
        assertEq(_bidA.isWon, true);
        IBillboardRegistry.Bid memory _bidB = registry.getBid(_tokenId, _nextAuctionId, USER_B);
        assertEq(_bidB.isWon, false);

        // withdraw bid
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.BidWithdrawn(_tokenId, _nextAuctionId, USER_B, _amount, _tax);

        vm.prank(USER_B);
        operator.withdrawBid(_tokenId, _nextAuctionId);
        assertEq(USER_B.balance, _total);
    }

    function testCannotWithBidTwice(uint96 _amount) public {
        vm.assume(_amount > 0.001 ether);

        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // new auction and new bid with USER_A
        vm.deal(USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid{value: _total}(_tokenId, _amount);

        // new bid with USER_B
        vm.deal(USER_B, _total);
        vm.prank(USER_B);
        operator.placeBid{value: _total}(_tokenId, _amount);

        // clear auction
        vm.warp(block.timestamp + registry.leaseTerm() + 1 minutes);
        operator.clearAuction(_tokenId);

        // check auction
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_A);

        // withdraw bid
        vm.prank(USER_B);
        operator.withdrawBid(_tokenId, _nextAuctionId);
        assertEq(USER_B.balance, _total);

        // withdraw bid again
        vm.prank(USER_B);
        vm.expectRevert(abi.encodeWithSignature("WithdrawFailed(string)", "withdrawn"));
        operator.withdrawBid(_tokenId, _nextAuctionId);
    }

    function testCannotWithdrawBidIfWon(uint96 _amount) public {
        vm.assume(_amount > 0.001 ether);

        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // new auction and new bid with USER_A
        vm.deal(USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid{value: _total}(_tokenId, _amount);

        // clear auction
        vm.warp(block.timestamp + registry.leaseTerm() + 1 minutes);
        operator.clearAuction(_tokenId);

        // check auction
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_A);

        // withdraw bid
        vm.prank(USER_A);
        vm.expectRevert(abi.encodeWithSignature("WithdrawFailed(string)", "won"));
        operator.withdrawBid(_tokenId, _nextAuctionId);
    }

    function testCannotWithdrawBidIfAuctionNotEnded(uint96 _amount) public {
        vm.assume(_amount > 0.001 ether);

        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // new auction and new bid with USER_A
        vm.startPrank(USER_A);
        vm.deal(USER_A, _total);
        operator.placeBid{value: _total}(_tokenId, _amount);

        // auction is not ended
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        vm.expectRevert(abi.encodeWithSignature("AuctionNotEnded()"));
        operator.withdrawBid(_tokenId, _nextAuctionId);

        // auction is ended but not cleared
        vm.warp(block.timestamp + registry.leaseTerm() + 1 seconds);
        vm.expectRevert(abi.encodeWithSignature("WithdrawFailed(string)", "auction not cleared"));
        operator.withdrawBid(_tokenId, _nextAuctionId);
    }

    function testCannotWithdrawBidIfAuctionNotCleared(uint96 _amount) public {
        vm.assume(_amount > 0.001 ether);

        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // new auction and new bid with USER_A
        vm.prank(USER_A);
        vm.deal(USER_A, _total);
        operator.placeBid{value: _total}(_tokenId, _amount);

        // new bid with USER_B
        vm.deal(USER_B, _total);
        vm.prank(USER_B);
        operator.placeBid{value: _total}(_tokenId, _amount);

        // auction is ended but not cleared
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        vm.warp(block.timestamp + registry.leaseTerm() + 1 seconds);
        vm.prank(USER_B);
        vm.expectRevert(abi.encodeWithSignature("WithdrawFailed(string)", "auction not cleared"));
        operator.withdrawBid(_tokenId, _nextAuctionId);
    }

    function testCannotWithdrawBidIfNotFound() public {
        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);

        vm.prank(USER_A);
        vm.expectRevert(abi.encodeWithSignature("BidNotFound()"));
        operator.withdrawBid(_tokenId, _nextAuctionId);
    }
}
