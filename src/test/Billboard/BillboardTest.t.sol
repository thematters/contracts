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
        Billboard newOperator = new Billboard(
            address(usdt),
            payable(registry),
            ADMIN,
            TAX_RATE,
            LEASE_TERM,
            BLOCKS_PER_DAY,
            "Billboard2",
            "BLBD2"
        );
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

        vm.expectRevert("Admin");
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

        vm.expectRevert("Admin");
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

        vm.expectRevert("Admin");
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

        vm.expectRevert("Admin");
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
        vm.expectRevert("Whitelist");
        operator.mintBoard(USER_A);

        vm.prank(ADMIN);
        operator.addToWhitelist(USER_A);

        vm.prank(USER_A);
        operator.mintBoard(USER_A);
        assertEq(registry.balanceOf(USER_A), 1);
    }

    function testCannotMintBoardByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert("Whitelist");
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

        vm.expectRevert("Creator");
        operator.setBoardName(_tokenId, "name");

        vm.expectRevert("Creator");
        operator.setBoardDescription(_tokenId, "description");

        vm.expectRevert("Creator");
        operator.setBoardLocation(_tokenId, "location");

        vm.expectRevert("Tenant");
        operator.setBoardContentURI(_tokenId, "uri");

        vm.expectRevert("Tenant");
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

        vm.expectRevert("Creator");
        operator.setBoardName(_tokenId, "name by a");

        vm.expectRevert("Creator");
        operator.setBoardDescription(_tokenId, "description by a");

        vm.expectRevert("Creator");
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

        vm.expectRevert("Creator");
        operator.setBoardName(_tokenId, "name by b");

        vm.expectRevert("Creator");
        operator.setBoardDescription(_tokenId, "description by b");

        vm.expectRevert("Creator");
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

        vm.expectRevert("Operator");
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
        uint256 _overpaid = 0.1 ether;
        uint256 _total = _amount + _tax;
        deal(address(usdt), USER_A, _total + _overpaid);

        uint256 _prevNextActionId = registry.nextBoardAuctionId(_tokenId);
        uint256 _prevCreatorBalance = usdt.balanceOf(ADMIN);
        uint256 _prevBidderBalance = usdt.balanceOf(USER_A);
        uint256 _prevOperatorBalance = usdt.balanceOf(address(operator));
        uint256 _prevRegistryBalance = usdt.balanceOf(address(registry));

        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.AuctionCreated(
            _tokenId,
            _prevNextActionId + 1,
            uint64(block.number),
            uint64(block.number)
        );
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.BidCreated(_tokenId, _prevNextActionId + 1, USER_A, _amount, _tax);
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.BidWon(_tokenId, _prevNextActionId + 1, USER_A);
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.AuctionCleared(
            _tokenId,
            _prevNextActionId + 1,
            USER_A,
            uint64(block.number),
            uint64(block.number + registry.leaseTerm())
        );

        vm.prank(USER_A);
        operator.placeBid(_tokenId, _amount);

        // check balances
        assertEq(usdt.balanceOf(ADMIN), _prevCreatorBalance + _amount);
        assertEq(usdt.balanceOf(USER_A), _prevBidderBalance - _total);
        assertEq(usdt.balanceOf(address(operator)), _prevOperatorBalance);
        assertEq(usdt.balanceOf(address(registry)), _prevRegistryBalance + _tax);

        // check auction
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_prevNextActionId, 0);
        assertEq(_nextAuctionId, _prevNextActionId + 1);
        assertEq(_auction.startAt, block.number);
        assertEq(_auction.endAt, block.number);
        assertEq(_auction.leaseStartAt, block.number);
        assertEq(_auction.leaseEndAt, block.number + registry.leaseTerm());
        assertEq(_auction.highestBidder, USER_A);

        // check bid
        IBillboardRegistry.Bid memory _bid = registry.getBid(_tokenId, _nextAuctionId, USER_A);
        assertEq(_bid.price, _amount);
        assertEq(_bid.tax, _tax);
        assertEq(_bid.placedAt, block.number);
        assertEq(_bid.isWon, true);
        assertEq(_bid.isWithdrawn, false);
    }

    function testPlaceBidWithSamePrices(uint96 _amount) public {
        (uint256 _tokenId, uint256 _prevNextAuctionId) = _mintBoardAndPlaceBid();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // new auction and new bid with USER_A
        deal(address(usdt), USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid(_tokenId, _amount);
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        assertEq(_nextAuctionId, _prevNextAuctionId + 1);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_A);

        // new bid with USER_B
        deal(address(usdt), USER_B, _total);
        vm.prank(USER_B);
        operator.placeBid(_tokenId, _amount);
        _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        assertEq(_nextAuctionId, _prevNextAuctionId + 1); // still the same auction
        _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_A); // USER_A is still the same highest bidder

        // check if bids exist
        IBillboardRegistry.Bid memory _bidA = registry.getBid(_tokenId, _nextAuctionId, USER_A);
        assertEq(_bidA.placedAt, block.number);
        assertEq(_bidA.isWon, false);
        IBillboardRegistry.Bid memory _bidB = registry.getBid(_tokenId, _nextAuctionId, USER_A);
        assertEq(_bidB.placedAt, block.number);
        assertEq(_bidB.isWon, false);

        // check registry balance
        assertEq(usdt.balanceOf(address(registry)), _total * 2);
    }

    function testPlaceBidWithHigherPrice(uint96 _amount) public {
        vm.assume(_amount > 0);
        vm.assume(_amount < type(uint96).max / 2);

        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // bid with USER_A
        deal(address(usdt), USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid(_tokenId, _amount);
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_A);

        // bid with USER_B
        _amount = _amount * 2;
        _tax = operator.calculateTax(_amount);
        _total = _amount + _tax;
        deal(address(usdt), USER_B, _total);
        vm.startPrank(USER_B);
        operator.placeBid(_tokenId, _amount);
        _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_B);
    }

    function testPlaceBidZeroPrice() public {
        uint256 _tokenId = _mintBoard();

        vm.startPrank(ADMIN);
        uint256 _prevBalance = usdt.balanceOf(ADMIN);

        operator.placeBid(_tokenId, 0);

        // check balances
        uint256 _afterBalance = usdt.balanceOf(ADMIN);
        assertEq(_afterBalance, _prevBalance);
        assertEq(usdt.balanceOf(address(operator)), 0);
        assertEq(usdt.balanceOf(address(registry)), 0);

        // check auction
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, ADMIN);

        // check bid
        IBillboardRegistry.Bid memory _bid = registry.getBid(_tokenId, _nextAuctionId, ADMIN);
        assertEq(_bid.placedAt, block.number);
        assertEq(_bid.isWon, true);
    }

    function testPlaceBidByWhitelist() public {
        uint256 _tokenId = _mintBoard();
        uint256 _amount = 1 ether;
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        vm.prank(ADMIN);
        operator.addToWhitelist(USER_A);

        deal(address(usdt), USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid(_tokenId, _amount);
        assertEq(usdt.balanceOf(USER_A), 0);
    }

    function testPlaceBidIfAuctionEnded() public {
        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _amount = 1 ether;
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // place a bid with USER_A
        vm.startPrank(USER_A);
        deal(address(usdt), USER_A, _total);
        operator.placeBid(_tokenId, _amount);

        // check auction
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_A);
        assertEq(_auction.endAt, block.number + registry.leaseTerm());

        // make auction ended
        vm.roll(_auction.endAt + 1);

        // place a bid with USER_B
        vm.startPrank(USER_B);
        deal(address(usdt), USER_B, _total);
        operator.placeBid(_tokenId, _amount);

        // check auction
        uint256 _newNextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _newAuction = registry.getAuction(_tokenId, _newNextAuctionId);
        assertEq(_newNextAuctionId, _nextAuctionId + 1);
        assertEq(_newAuction.highestBidder, USER_B);
        assertEq(_newAuction.endAt, block.number + registry.leaseTerm());

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
        deal(address(usdt), USER_A, _total);
        operator.placeBid(_tokenId, _amount);
        assertEq(usdt.balanceOf(USER_A), 0);

        deal(address(usdt), USER_A, _total);
        vm.expectRevert("Bid already placed");
        operator.placeBid(_tokenId, _amount);
    }

    function testCannotPlaceBidByAttacker() public {
        uint256 _tokenId = _mintBoard();
        uint256 _amount = 1 ether;
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        vm.startPrank(ATTACKER);
        deal(address(usdt), ATTACKER, _total);
        vm.expectRevert("Whitelist");
        operator.placeBid(_tokenId, _amount);
    }

    function testClearAuctionIfAuctionEnded(uint96 _amount) public {
        vm.assume(_amount > 0.001 ether);

        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        (uint256 _tokenId, uint256 _prevAuctionId) = _mintBoardAndPlaceBid();
        uint64 _placedAt = uint64(block.number);
        uint64 _clearedAt = uint64(block.number) + registry.leaseTerm() + 1;

        // place a bid
        vm.startPrank(USER_A);
        deal(address(usdt), USER_A, _total);
        operator.placeBid(_tokenId, _amount);

        // clear auction
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.AuctionCleared(
            _tokenId,
            _prevAuctionId + 1,
            USER_A,
            _clearedAt,
            _clearedAt + registry.leaseTerm()
        );

        vm.roll(_clearedAt);
        (uint256 _price1, uint256 _tax1) = operator.clearAuction(_tokenId);
        assertEq(_price1, _amount);
        assertEq(_tax1, _tax);

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
        assertEq(_bid.price, _amount);
        assertEq(_bid.tax, _tax);
        assertEq(_bid.placedAt, _placedAt);
        assertEq(_bid.isWon, true);
        assertEq(_bid.isWithdrawn, false);
    }

    function testClearAuctionsIfAuctionEnded() public {
        (uint256 _tokenId, uint256 _prevAuctionId) = _mintBoardAndPlaceBid();
        (uint256 _tokenId2, uint256 _prevAuctionId2) = _mintBoardAndPlaceBid();

        uint64 _placedAt = uint64(block.number);
        uint64 _clearedAt = uint64(block.number) + registry.leaseTerm() + 1;

        // place bids
        vm.startPrank(USER_A);
        deal(address(usdt), USER_A, 0);
        operator.placeBid(_tokenId, 0);

        vm.startPrank(USER_B);
        deal(address(usdt), USER_B, 0);
        operator.placeBid(_tokenId2, 0);

        // clear auction
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.AuctionCleared(
            _tokenId,
            _prevAuctionId + 1,
            USER_A,
            _clearedAt,
            _clearedAt + registry.leaseTerm()
        );
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.AuctionCleared(
            _tokenId2,
            _prevAuctionId2 + 1,
            USER_B,
            _clearedAt,
            _clearedAt + registry.leaseTerm()
        );

        vm.roll(_clearedAt);

        uint256[] memory _tokenIds = new uint256[](2);
        _tokenIds[0] = _tokenId;
        _tokenIds[1] = _tokenId2;
        (uint256[] memory prices, uint256[] memory taxes) = operator.clearAuctions(_tokenIds);
        assertEq(prices[0], 0);
        assertEq(prices[1], 0);
        assertEq(taxes[0], 0);
        assertEq(taxes[1], 0);

        // check auction
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.startAt, _placedAt);
        assertEq(_auction.endAt, _placedAt + registry.leaseTerm());
        assertEq(_auction.leaseStartAt, _clearedAt);
        assertEq(_auction.leaseEndAt, _clearedAt + registry.leaseTerm());
        assertEq(_auction.highestBidder, USER_A);

        uint256 _nextAuctionId2 = registry.nextBoardAuctionId(_tokenId2);
        IBillboardRegistry.Auction memory _auction2 = registry.getAuction(_tokenId2, _nextAuctionId2);
        assertEq(_auction2.startAt, _placedAt);
        assertEq(_auction2.endAt, _placedAt + registry.leaseTerm());
        assertEq(_auction2.leaseStartAt, _clearedAt);
        assertEq(_auction2.leaseEndAt, _clearedAt + registry.leaseTerm());
        assertEq(_auction2.highestBidder, USER_B);

        // check bid
        IBillboardRegistry.Bid memory _bid = registry.getBid(_tokenId, _nextAuctionId, USER_A);
        assertEq(_bid.price, 0);
        assertEq(_bid.tax, 0);
        assertEq(_bid.placedAt, _placedAt);
        assertEq(_bid.isWon, true);
        assertEq(_bid.isWithdrawn, false);

        IBillboardRegistry.Bid memory _bid2 = registry.getBid(_tokenId2, _nextAuctionId2, USER_B);
        assertEq(_bid2.price, 0);
        assertEq(_bid2.tax, 0);
        assertEq(_bid2.placedAt, _placedAt);
        assertEq(_bid2.isWon, true);
        assertEq(_bid2.isWithdrawn, false);
    }

    function testCannotClearAuctionOnNewBoard() public {
        uint256 _mintedAt = block.number;
        uint256 _clearedAt = _mintedAt + 1;
        uint256 _tokenId = _mintBoard();

        vm.startPrank(ADMIN);

        // clear auction
        vm.roll(_clearedAt);
        vm.expectRevert("Auction not found");
        operator.clearAuction(_tokenId);
    }

    function testCannotClearAuctionIfAuctionNotEnded() public {
        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();

        // place a bid
        vm.startPrank(USER_A);
        deal(address(usdt), USER_A, 0);
        operator.placeBid(_tokenId, 0);

        // try to clear auction
        vm.expectRevert("Auction not ended");
        operator.clearAuction(_tokenId);

        vm.roll(block.number + registry.leaseTerm() - 1);
        vm.expectRevert("Auction not ended");
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

            deal(address(usdt), _bidder, _totalAmount);
            vm.startPrank(_bidder);
            usdt.approve(address(operator), _totalAmount);
            operator.placeBid(_tokenId, _amount);
            vm.stopPrank();
        }

        // get bids
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
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
        uint256 _taxRate = 10; // 10% per lease term
        uint64 _leaseTerm = registry.leaseTerm();
        uint64 _blocksPerDay = registry.blocksPerDay();

        vm.startPrank(ADMIN);
        operator.setTaxRate(_taxRate);

        uint256 _tax = operator.calculateTax(_amount);
        assertEq(_tax, (_amount * _taxRate * (_leaseTerm / _blocksPerDay)) / 100);
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

        vm.expectRevert("Admin");
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
        deal(address(usdt), USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid(_tokenId, _amount);

        uint256 _prevRegistryBalance = usdt.balanceOf(address(registry));
        uint256 _prevAdminBalance = usdt.balanceOf(ADMIN);

        // withdraw tax
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.TaxWithdrawn(ADMIN, _tax);

        vm.prank(ADMIN);
        operator.withdrawTax();

        // check balances
        assertEq(usdt.balanceOf(address(registry)), _prevRegistryBalance - _tax);
        assertEq(usdt.balanceOf(ADMIN), _prevAdminBalance + _tax);
    }

    function testCannnotWithdrawTaxIfZero() public {
        uint256 _tokenId = _mintBoard();

        vm.prank(ADMIN);
        operator.addToWhitelist(USER_A);

        // place a bid and win auction
        deal(address(usdt), USER_A, 0);
        vm.prank(USER_A);
        operator.placeBid(_tokenId, 0);

        vm.prank(ADMIN);
        vm.expectRevert("Zero amount");
        operator.withdrawTax();
    }

    function testCannnotWithdrawTaxIfSmallAmount(uint8 _amount) public {
        uint256 _tax = operator.calculateTax(_amount);
        vm.assume(_tax <= 0);

        uint256 _tokenId = _mintBoard();

        vm.prank(ADMIN);
        operator.addToWhitelist(USER_A);

        // place a bid and win auction
        deal(address(usdt), USER_A, _amount);
        vm.prank(USER_A);
        operator.placeBid(_tokenId, _amount);

        vm.prank(ADMIN);
        vm.expectRevert("Zero amount");
        operator.withdrawTax();
    }

    function testCannotWithdrawTaxByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert("Zero amount");
        operator.withdrawTax();
    }

    function testWithdrawBid(uint96 _amount) public {
        vm.assume(_amount > 0.001 ether);

        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // new auction and new bid with USER_A
        deal(address(usdt), USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid(_tokenId, _amount);

        // new bid with USER_B
        deal(address(usdt), USER_B, _total);
        vm.prank(USER_B);
        operator.placeBid(_tokenId, _amount);

        // clear auction
        vm.roll(block.number + registry.leaseTerm() + 1);
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
        assertEq(usdt.balanceOf(USER_B), _total);
    }

    function testCannotWithBidTwice(uint96 _amount) public {
        vm.assume(_amount > 0.001 ether);

        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // new auction and new bid with USER_A
        deal(address(usdt), USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid(_tokenId, _amount);

        // new bid with USER_B
        deal(address(usdt), USER_B, _total);
        vm.prank(USER_B);
        operator.placeBid(_tokenId, _amount);

        // clear auction
        vm.roll(block.number + registry.leaseTerm() + 1);
        operator.clearAuction(_tokenId);

        // check auction
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_A);

        // withdraw bid
        vm.prank(USER_B);
        operator.withdrawBid(_tokenId, _nextAuctionId);
        assertEq(usdt.balanceOf(USER_B), _total);

        // withdraw bid again
        vm.prank(USER_B);
        vm.expectRevert("Bid already withdrawn");
        operator.withdrawBid(_tokenId, _nextAuctionId);
    }

    function testCannotWithdrawBidIfWon(uint96 _amount) public {
        vm.assume(_amount > 0.001 ether);

        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // new auction and new bid with USER_A
        deal(address(usdt), USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid(_tokenId, _amount);

        // clear auction
        vm.roll(block.number + registry.leaseTerm() + 1);
        operator.clearAuction(_tokenId);

        // check auction
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        IBillboardRegistry.Auction memory _auction = registry.getAuction(_tokenId, _nextAuctionId);
        assertEq(_auction.highestBidder, USER_A);

        // withdraw bid
        vm.prank(USER_A);
        vm.expectRevert("Bid already won");
        operator.withdrawBid(_tokenId, _nextAuctionId);
    }

    function testCannotWithdrawBidIfAuctionNotEnded(uint96 _amount) public {
        vm.assume(_amount > 0.001 ether);

        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // new auction and new bid with USER_A
        vm.startPrank(USER_A);
        deal(address(usdt), USER_A, _total);
        operator.placeBid(_tokenId, _amount);

        // auction is not ended
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        vm.expectRevert("Auction not ended");
        operator.withdrawBid(_tokenId, _nextAuctionId);

        // auction is ended but not cleared
        vm.roll(block.number + registry.leaseTerm() + 1);
        vm.expectRevert("Auction not cleared");
        operator.withdrawBid(_tokenId, _nextAuctionId);
    }

    function testCannotWithdrawBidIfAuctionNotCleared(uint96 _amount) public {
        vm.assume(_amount > 0.001 ether);

        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _tax = operator.calculateTax(_amount);
        uint256 _total = _amount + _tax;

        // new auction and new bid with USER_A
        deal(address(usdt), USER_A, _total);
        vm.prank(USER_A);
        operator.placeBid(_tokenId, _amount);

        // new bid with USER_B
        deal(address(usdt), USER_B, _total);
        vm.prank(USER_B);
        operator.placeBid(_tokenId, _amount);

        // auction is ended but not cleared
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);
        vm.roll(block.number + registry.leaseTerm() + 1);
        vm.prank(USER_B);
        vm.expectRevert("Auction not cleared");
        operator.withdrawBid(_tokenId, _nextAuctionId);
    }

    function testCannotWithdrawBidIfNotFound() public {
        (uint256 _tokenId, ) = _mintBoardAndPlaceBid();
        uint256 _nextAuctionId = registry.nextBoardAuctionId(_tokenId);

        vm.prank(USER_A);
        vm.expectRevert("Bid not found");
        operator.withdrawBid(_tokenId, _nextAuctionId);
    }

    //////////////////////////////
    /// Block
    //////////////////////////////

    function testSetBlocksPerDay() public {
        vm.startPrank(ADMIN);

        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.BlocksPerDayUpdated(200);

        operator.setBlocksPerDay(200);
        assertEq(operator.getBlocksPerDay(), 200);
    }

    function testCannotSetBlocksPerDayByAttacker() public {
        vm.startPrank(ATTACKER);

        vm.expectRevert("Admin");
        operator.setBlocksPerDay(100);
    }
}
