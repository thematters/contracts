//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./BillboardTestBase.t.sol";

contract BillboardTest is BillboardTestBase {
    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    function testUpgradeRegistry() public {
        vm.startPrank(ADMIN);

        // deploy new operator
        Billboard newOperator = new Billboard(address(usdt), payable(registry), ADMIN, "Billboard2", "BLBD2");
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

    function testSetWhitelist() public {
        (uint256 _tokenId, ) = _mintBoard();

        vm.startPrank(ADMIN);

        // add to whitelist
        operator.setWhitelist(_tokenId, USER_A, true);
        assertEq(operator.whitelist(_tokenId, USER_A), true);
        assertEq(operator.whitelist(_tokenId, USER_B), false);

        // remove from whitelist
        operator.setWhitelist(_tokenId, USER_A, false);
        assertEq(operator.whitelist(_tokenId, USER_A), false);
    }

    function testCannotSetWhitelistByAttacker() public {
        (uint256 _tokenId, ) = _mintBoard();

        vm.startPrank(ATTACKER);

        vm.expectRevert("Creator");
        operator.setWhitelist(_tokenId, USER_B, false);
    }

    function testSetClosed() public {
        (uint256 _tokenId, ) = _mintBoard();

        vm.startPrank(ADMIN);

        // set closed
        operator.setClosed(_tokenId, true);
        assertEq(operator.closed(_tokenId), true);

        // set open
        operator.setClosed(_tokenId, false);
        assertEq(operator.closed(_tokenId), false);
    }

    function testCannotSetClosedByAttacker() public {
        (uint256 _tokenId, ) = _mintBoard();

        vm.startPrank(ATTACKER);

        vm.expectRevert("Creator");
        operator.setClosed(_tokenId, true);
    }

    //////////////////////////////
    /// Board
    //////////////////////////////

    function testMintBoard() public {
        vm.startPrank(ADMIN);

        // mint
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), ADMIN, 1);
        uint256 _tokenId = operator.mintBoard(TAX_RATE, EPOCH_INTERVAL);

        // ownership
        assertEq(registry.balanceOf(ADMIN), 1);
        assertEq(registry.ownerOf(_tokenId), ADMIN);

        // data
        IBillboardRegistry.Board memory _board = operator.getBoard(_tokenId);
        assertEq(_board.creator, ADMIN);
        assertEq(_board.name, "");
        assertEq(_board.description, "");
        assertEq(_board.imageURI, "");
        assertEq(_board.location, "");
        assertEq(_board.taxRate, TAX_RATE);
        assertEq(_board.epochInterval, EPOCH_INTERVAL);
        assertEq(_board.startedAt, block.number);

        vm.stopPrank();
        vm.startPrank(USER_A);

        // mint by user and check token id
        uint256 _newTokenId = 2;
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), USER_A, _newTokenId);
        uint256 _tokenId2 = operator.mintBoard(TAX_RATE, EPOCH_INTERVAL);
        assertEq(_tokenId2, _newTokenId);
        assertEq(registry.balanceOf(USER_A), 1);
        IBillboardRegistry.Board memory _board2 = operator.getBoard(_tokenId2);
        assertEq(_board2.creator, USER_A);

        // mint with startedAt
        uint256 _startedAt = block.number + 100;
        uint256 _tokenId3 = operator.mintBoard(TAX_RATE, EPOCH_INTERVAL, _startedAt);
        IBillboardRegistry.Board memory _board3 = operator.getBoard(_tokenId3);
        assertEq(_board3.startedAt, _startedAt);
    }

    function testSetBoardByCreator() public {
        (uint256 _tokenId, ) = _mintBoard();
        string memory _name = "name";
        string memory _description = "description";
        string memory _imageURI = "image URI";
        string memory _location = "location";

        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.BoardUpdated(_tokenId, _name, _description, _imageURI, _location);

        vm.startPrank(ADMIN);
        operator.setBoard(_tokenId, _name, _description, _imageURI, _location);

        IBillboardRegistry.Board memory board = operator.getBoard(_tokenId);
        assertEq(board.name, _name);
        assertEq(board.description, _description);
        assertEq(board.imageURI, _imageURI);
        assertEq(board.location, _location);
    }

    function testCannotSetBoardByAttacker() public {
        (uint256 _tokenId, ) = _mintBoard();

        vm.startPrank(ATTACKER);

        vm.expectRevert("Creator");
        operator.setBoard(_tokenId, "", "", "", "");
    }

    function testCannotSetBoardByOwner() public {
        // mint
        (uint256 _tokenId, ) = _mintBoard();

        // transfer
        vm.startPrank(ADMIN);
        registry.transferFrom(ADMIN, USER_A, _tokenId);

        IBillboardRegistry.Board memory board = operator.getBoard(_tokenId);
        assertEq(board.creator, ADMIN);
        assertEq(registry.balanceOf(ADMIN), 0);
        assertEq(registry.ownerOf(_tokenId), USER_A);

        // cannot set board by new owner
        vm.stopPrank();
        vm.startPrank(USER_A);
        vm.expectRevert("Creator");
        operator.setBoard(_tokenId, "name", "description", "image URI", "location");

        // can set board by creator
        vm.stopPrank();
        vm.startPrank(ADMIN);
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.BoardUpdated(_tokenId, "name", "description", "image URI", "location");
        operator.setBoard(_tokenId, "name", "description", "image URI", "location");
    }

    //////////////////////////////
    /// Auction & Bid
    //////////////////////////////

    function testPlaceBid(uint96 _price) public {
        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _tax = operator.calculateTax(_tokenId, _price);
        uint256 _total = _price + _tax;
        deal(address(usdt), USER_A, _total);

        uint256 _prevCreatorBalance = usdt.balanceOf(ADMIN);
        uint256 _prevBidderBalance = usdt.balanceOf(USER_A);
        uint256 _prevOperatorBalance = usdt.balanceOf(address(operator));
        uint256 _prevRegistryBalance = usdt.balanceOf(address(registry));

        vm.startPrank(ADMIN);
        operator.setWhitelist(_tokenId, USER_A, true);
        operator.setWhitelist(_tokenId, USER_B, true);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.BidUpdated(_tokenId, _epoch, USER_A, _price, _tax, "", "");

        vm.prank(USER_A);
        operator.placeBid(_tokenId, _epoch, _price);

        // check balances
        assertEq(usdt.balanceOf(ADMIN), _prevCreatorBalance);
        assertEq(usdt.balanceOf(USER_A), _prevBidderBalance - _total);
        assertEq(usdt.balanceOf(address(operator)), _prevOperatorBalance);
        assertEq(usdt.balanceOf(address(registry)), _prevRegistryBalance + _total);

        // check bid
        IBillboardRegistry.Bid memory _bid = registry.getBid(_tokenId, _epoch, USER_A);
        assertEq(_bid.price, _price);
        assertEq(_bid.tax, _tax);
        assertEq(_bid.placedAt, block.number);
        assertEq(_bid.updatedAt, block.number);
        assertEq(_bid.isWon, false);
        assertEq(_bid.isWithdrawn, false);

        // bid with AD data
        string memory _contentURI = "content URI";
        string memory _redirectURI = "redirect URI";
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.BidUpdated(_tokenId, _epoch, USER_B, 0, 0, _contentURI, _redirectURI);

        vm.prank(USER_B);
        operator.placeBid(_tokenId, _epoch, 0, _contentURI, _redirectURI);
    }

    function testPlaceBidWithSamePrices(uint96 _price) public {
        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _tax = operator.calculateTax(_tokenId, _price);
        uint256 _total = _price + _tax;

        // bid with USER_A
        _placeBid(_tokenId, _epoch, USER_A, _price);
        assertEq(registry.highestBidder(_tokenId, _epoch), USER_A);

        // bid with USER_B
        _placeBid(_tokenId, _epoch, USER_B, _price);
        assertEq(registry.highestBidder(_tokenId, _epoch), USER_A); // USER_A is still the same highest bidder

        // check bids
        IBillboardRegistry.Bid memory _bidA = registry.getBid(_tokenId, _epoch, USER_A);
        assertEq(_bidA.placedAt, block.number);
        assertEq(_bidA.isWon, false);
        IBillboardRegistry.Bid memory _bidB = registry.getBid(_tokenId, _epoch, USER_A);
        assertEq(_bidB.placedAt, block.number);
        assertEq(_bidB.isWon, false);

        // check registry balance
        assertEq(usdt.balanceOf(address(registry)), _total * 2);
    }

    function testPlaceBidWithHigherPrice(uint96 _price) public {
        vm.assume(_price > 0);
        vm.assume(_price < type(uint96).max / 4);

        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _tax = operator.calculateTax(_tokenId, _price);

        uint256 _placedAt = block.number;
        uint256 _updatedAt = block.number + 1;

        // bid with USER_A
        _placeBid(_tokenId, _epoch, USER_A, _price);
        assertEq(registry.highestBidder(_tokenId, _epoch), USER_A);

        // bid with USER_B
        uint256 _priceB = _price * 2;
        _placeBid(_tokenId, _epoch, USER_B, _priceB);
        assertEq(registry.highestBidder(_tokenId, _epoch), USER_B);

        // bid with USER_A
        vm.roll(_updatedAt);
        uint256 _priceA = _price * 4;
        uint256 _taxA = operator.calculateTax(_tokenId, _priceA);
        uint256 _totalA = _priceA + _taxA;
        _placeBid(_tokenId, _epoch, USER_A, _priceA);
        assertEq(registry.highestBidder(_tokenId, _epoch), USER_A);

        // check balance of USER_A
        uint256 _priceDiff = _priceA - _price;
        uint256 _taxDiff = _taxA - _tax;
        uint256 _totalDiff = _priceDiff + _taxDiff;
        assertEq(usdt.balanceOf(USER_A), _totalA - _totalDiff);

        // check bid
        IBillboardRegistry.Bid memory _bidA = registry.getBid(_tokenId, _epoch, USER_A);
        assertEq(_bidA.price, _priceA);
        assertEq(_bidA.tax, _taxA);
        assertEq(_bidA.placedAt, _placedAt);
        assertEq(_bidA.updatedAt, _updatedAt);
    }

    function testPlaceBidZeroPrice() public {
        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _prevBalance = usdt.balanceOf(ADMIN);

        vm.startPrank(ADMIN);
        operator.placeBid(_tokenId, _epoch, 0);
        assertEq(registry.highestBidder(_tokenId, _epoch), ADMIN);

        // check balances
        uint256 _afterBalance = usdt.balanceOf(ADMIN);
        assertEq(_afterBalance, _prevBalance);
        assertEq(usdt.balanceOf(address(operator)), 0);
        assertEq(usdt.balanceOf(address(registry)), 0);

        // check bid
        IBillboardRegistry.Bid memory _bid = registry.getBid(_tokenId, _epoch, ADMIN);
        assertEq(_bid.placedAt, block.number);
        assertEq(_bid.isWon, false);
    }

    function testCannotPlaceBidIfClosed() public {
        (uint256 _tokenId, ) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(block.number, block.number, 1);

        vm.startPrank(ADMIN);
        operator.setClosed(_tokenId, true);

        vm.expectRevert("Closed");
        operator.placeBid(_tokenId, _epoch, 1 ether);
    }

    function testCannotPlaceBidIfAuctionEnded() public {
        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _price = 1 ether;

        uint256 _endedAt = operator.getBlockFromEpoch(_board.startedAt, _epoch + 1, _board.epochInterval);

        vm.prank(ADMIN);
        operator.setWhitelist(_tokenId, USER_A, true);

        vm.startPrank(USER_A);

        vm.roll(_endedAt);
        vm.expectRevert("Auction ended");
        operator.placeBid(_tokenId, _epoch, _price);

        vm.roll(_endedAt + 1);
        vm.expectRevert("Auction ended");
        operator.placeBid(_tokenId, _epoch, _price);
    }

    function testCannotPlaceBidIfNotWhitelisted() public {
        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _price = 1 ether;
        uint256 _tax = operator.calculateTax(_tokenId, _price);
        uint256 _total = _price + _tax;
        deal(address(usdt), USER_A, _total);

        vm.startPrank(ATTACKER);
        deal(address(usdt), ATTACKER, _total);
        vm.expectRevert("Whitelist");
        operator.placeBid(_tokenId, _epoch, _price);
    }

    function testSetBidURIs() public {
        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);

        _placeBid(_tokenId, _epoch, USER_A, 1 ether);

        // check bid
        IBillboardRegistry.Bid memory _bid = registry.getBid(_tokenId, _epoch, USER_A);
        assertEq(_bid.contentURI, "");
        assertEq(_bid.redirectURI, "");

        // set bid AD data
        string memory _contentURI = "content URI";
        string memory _redirectURI = "redirect URI";

        vm.prank(USER_A);
        operator.setBidURIs(_tokenId, _epoch, _contentURI, _redirectURI);

        IBillboardRegistry.Bid memory _newBid = registry.getBid(_tokenId, _epoch, USER_A);
        assertEq(_newBid.contentURI, _contentURI);
        assertEq(_newBid.redirectURI, _redirectURI);
    }

    function testClearAuction(uint96 _price) public {
        vm.assume(_price > 0.001 ether);

        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _tax = operator.calculateTax(_tokenId, _price);
        uint256 _placedAt = block.number;
        uint256 _clearedAt = operator.getBlockFromEpoch(_board.startedAt, _epoch + 1, _board.epochInterval);

        // place bid
        _placeBid(_tokenId, _epoch, USER_A, _price);

        // clear auction
        vm.expectEmit(true, true, true, false);
        emit IBillboardRegistry.AuctionCleared(_tokenId, _epoch, USER_A);

        vm.roll(_clearedAt);
        (address _highestBidder, uint256 _price1, uint256 _tax1) = operator.clearAuction(_tokenId, _epoch);

        assertEq(_price1, _price);
        assertEq(_tax1, _tax);
        assertEq(_highestBidder, registry.highestBidder(_tokenId, _epoch));
        assertEq(_highestBidder, USER_A);

        // check auction & bid
        IBillboardRegistry.Bid memory _bid = registry.getBid(_tokenId, _epoch, USER_A);
        assertEq(_bid.price, _price);
        assertEq(_bid.tax, _tax);
        assertEq(_bid.placedAt, _placedAt);
        assertEq(_bid.isWon, true);
        assertEq(_bid.isWithdrawn, false);

        // check balances
        assertEq(usdt.balanceOf(address(registry)), _tax);
        assertEq(usdt.balanceOf(ADMIN), _price);
        assertEq(usdt.balanceOf(USER_A), 0);
    }

    function testClearAuctions() public {
        (uint256 _tokenId1, IBillboardRegistry.Board memory _board1) = _mintBoard();
        (uint256 _tokenId2, IBillboardRegistry.Board memory _board2) = _mintBoard();
        uint256 _epoch1 = operator.getEpochFromBlock(_board1.startedAt, block.number, _board1.epochInterval);
        uint256 _epoch2 = operator.getEpochFromBlock(_board2.startedAt, block.number, _board2.epochInterval);
        _placeBid(_tokenId1, _epoch1, USER_A, 1 ether);
        _placeBid(_tokenId2, _epoch2, USER_B, 1 ether);

        uint256 _clearedAt = operator.getBlockFromEpoch(_board1.startedAt, _epoch1 + 1, _board1.epochInterval);

        // clear auctions
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.AuctionCleared(_tokenId1, _epoch1, USER_A);
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.AuctionCleared(_tokenId2, _epoch2, USER_B);

        vm.roll(_clearedAt);

        uint256[] memory _tokenIds = new uint256[](2);
        uint256[] memory _epochs = new uint256[](2);
        _tokenIds[0] = _tokenId1;
        _tokenIds[1] = _tokenId2;
        _epochs[0] = _epoch1;
        _epochs[1] = _epoch2;
        (address[] memory highestBidders, , ) = operator.clearAuctions(_tokenIds, _epochs);
        assertEq(highestBidders[0], USER_A);
        assertEq(highestBidders[1], USER_B);

        // check auction & bids
        IBillboardRegistry.Bid memory _bid1 = registry.getBid(_tokenId1, _epoch1, USER_A);
        assertEq(_bid1.isWon, true);

        IBillboardRegistry.Bid memory _bid2 = registry.getBid(_tokenId2, _epoch2, USER_B);
        assertEq(_bid2.isWon, true);
    }

    function testCannotClearAuctionIfClosed() public {
        (uint256 _tokenId, ) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(block.number, block.number, 1);

        vm.startPrank(ADMIN);
        operator.setClosed(_tokenId, true);

        vm.expectRevert("Closed");
        operator.clearAuction(_tokenId, _epoch);
    }

    function testCannotClearAuctionIfAuctionNotEnded() public {
        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _endedAt = operator.getBlockFromEpoch(_board.startedAt, _epoch + 1, _board.epochInterval);

        vm.expectRevert("Auction not ended");
        operator.clearAuction(_tokenId, _epoch);

        vm.roll(_endedAt - 1);
        vm.expectRevert("Auction not ended");
        operator.clearAuction(_tokenId, _epoch);
    }

    function testCannotClearAuctionIfNoBid() public {
        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _clearedAt = operator.getBlockFromEpoch(_board.startedAt, _epoch + 1, _board.epochInterval);

        vm.roll(_clearedAt);
        vm.expectRevert("No bid");
        operator.clearAuction(_tokenId, _epoch);
    }

    function testGetBids(uint8 _bidCount, uint8 _limit, uint8 _offset) public {
        vm.assume(_bidCount > 0);
        vm.assume(_bidCount <= 64);
        vm.assume(_limit <= _bidCount);
        vm.assume(_offset <= _limit);

        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);

        for (uint8 i = 0; i < _bidCount; i++) {
            address _bidder = address(uint160(2000 + i));

            vm.prank(ADMIN);
            operator.setWhitelist(_tokenId, _bidder, true);

            uint256 _price = 1 ether + i;
            uint256 _tax = operator.calculateTax(_tokenId, _price);
            uint256 _totalAmount = _price + _tax;

            deal(address(usdt), _bidder, _totalAmount);
            vm.startPrank(_bidder);
            usdt.approve(address(operator), _totalAmount);
            operator.placeBid(_tokenId, _epoch, _price);
            vm.stopPrank();
        }

        // get bids
        (uint256 _t, uint256 _l, uint256 _o, IBillboardRegistry.Bid[] memory _bids) = operator.getBids(
            _tokenId,
            _epoch,
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
            uint256 _price = 1 ether + _offset + i;
            assertEq(_bids[i].price, _price);
        }
    }

    function testWithdrawBid(uint96 _price) public {
        vm.assume(_price > 0.001 ether);

        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _tax = operator.calculateTax(_tokenId, _price);
        uint256 _total = _price + _tax;
        uint256 _clearedAt = operator.getBlockFromEpoch(_board.startedAt, _epoch + 1, _board.epochInterval);

        // new bid with USER_A
        _placeBid(_tokenId, _epoch, USER_A, _price);

        // new bid with USER_B
        _placeBid(_tokenId, _epoch, USER_B, _price);

        // clear auction
        vm.roll(_clearedAt);
        operator.clearAuction(_tokenId, _epoch);

        // check bid
        IBillboardRegistry.Bid memory _bidA = registry.getBid(_tokenId, _epoch, USER_A);
        assertEq(_bidA.isWon, true);
        IBillboardRegistry.Bid memory _bidB = registry.getBid(_tokenId, _epoch, USER_B);
        assertEq(_bidB.isWon, false);

        // withdraw bid
        vm.expectEmit(true, true, true, false);
        emit IBillboardRegistry.BidWithdrawn(_tokenId, _epoch, USER_B);

        vm.prank(USER_B);
        operator.withdrawBid(_tokenId, _epoch, USER_B);

        // check balances
        assertEq(usdt.balanceOf(USER_A), 0);
        assertEq(usdt.balanceOf(USER_B), _total);
    }

    function testWithdrawBidIfClosed(uint96 _price) public {
        vm.assume(_price > 0.001 ether);

        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _tax = operator.calculateTax(_tokenId, _price);
        uint256 _total = _price + _tax;

        // bid with USER_A
        _placeBid(_tokenId, _epoch, USER_A, _price);

        // set closed
        vm.prank(ADMIN);
        operator.setClosed(_tokenId, true);

        // withdraw bid
        vm.expectEmit(true, true, true, false);
        emit IBillboardRegistry.BidWithdrawn(_tokenId, _epoch, USER_A);

        vm.prank(USER_A);
        operator.withdrawBid(_tokenId, _epoch, USER_A);

        // check balances
        assertEq(usdt.balanceOf(USER_A), _total);

        // check bid
        IBillboardRegistry.Bid memory _bid = registry.getBid(_tokenId, _epoch, USER_A);
        assertEq(_bid.isWithdrawn, true);
    }

    function testCannotWithdrawBidTwice(uint96 _price) public {
        vm.assume(_price > 0.001 ether);

        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _tax = operator.calculateTax(_tokenId, _price);
        uint256 _total = _price + _tax;
        uint256 _clearedAt = operator.getBlockFromEpoch(_board.startedAt, _epoch + 1, _board.epochInterval);

        // new bid with USER_A
        _placeBid(_tokenId, _epoch, USER_A, _price);

        // new bid with USER_B
        _placeBid(_tokenId, _epoch, USER_B, _price);

        // clear auction
        vm.roll(_clearedAt);
        operator.clearAuction(_tokenId, _epoch);

        // withdraw bid
        vm.prank(USER_B);
        operator.withdrawBid(_tokenId, _epoch, USER_B);
        assertEq(usdt.balanceOf(USER_B), _total);

        // withdraw bid again
        vm.prank(USER_B);
        vm.expectRevert("Bid already withdrawn");
        operator.withdrawBid(_tokenId, _epoch, USER_B);
    }

    function testCannotWithdrawBidIfWon(uint96 _price) public {
        vm.assume(_price > 0.001 ether);

        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _clearedAt = operator.getBlockFromEpoch(_board.startedAt, _epoch + 1, _board.epochInterval);

        // new bid with USER_A
        _placeBid(_tokenId, _epoch, USER_A, _price);

        // new bid with USER_B
        _placeBid(_tokenId, _epoch, USER_B, _price);

        // clear auction
        vm.roll(_clearedAt);
        operator.clearAuction(_tokenId, _epoch);

        // withdraw bid
        vm.prank(USER_A);
        vm.expectRevert("Bid already won");
        operator.withdrawBid(_tokenId, _epoch, USER_A);
    }

    function testCannotWithdrawBidIfAuctionNotEndedOrCleared(uint96 _price) public {
        vm.assume(_price > 0.001 ether);

        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _clearedAt = operator.getBlockFromEpoch(_board.startedAt, _epoch + 1, _board.epochInterval);

        // new bid with USER_A
        _placeBid(_tokenId, _epoch, USER_A, _price);

        // auction is not ended
        vm.roll(_clearedAt - 1);
        vm.expectRevert("Auction not ended");
        operator.withdrawBid(_tokenId, _epoch, USER_A);

        // auction is ended but not cleared
        vm.roll(_clearedAt);
        vm.expectRevert("Auction not cleared");
        operator.withdrawBid(_tokenId, _epoch, USER_A);
    }

    function testCannotWithdrawBidIfNotFound(uint96 _price) public {
        vm.assume(_price > 0.001 ether);

        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _clearedAt = operator.getBlockFromEpoch(_board.startedAt, _epoch + 1, _board.epochInterval);

        // new bid with USER_A
        _placeBid(_tokenId, _epoch, USER_A, _price);

        // clear auction
        vm.roll(_clearedAt);
        operator.clearAuction(_tokenId, _epoch);

        vm.prank(USER_B);
        vm.expectRevert("Bid not found");
        operator.withdrawBid(_tokenId, _epoch, USER_B);
    }

    function testGetEpochFromBlock() public {
        // epoch interval = 1
        assertEq(operator.getEpochFromBlock(0, 0, 1), 0);
        assertEq(operator.getEpochFromBlock(0, 1, 1), 1);
        assertEq(operator.getEpochFromBlock(100, 100, 1), 0);
        assertEq(operator.getEpochFromBlock(100, 101, 1), 1);

        // epoch interval = 101
        assertEq(operator.getEpochFromBlock(0, 0, 101), 0);
        assertEq(operator.getEpochFromBlock(0, 1, 101), 0);
        assertEq(operator.getEpochFromBlock(0, 100, 101), 0);
        assertEq(operator.getEpochFromBlock(0, 101, 101), 1);
        assertEq(operator.getEpochFromBlock(0, 203, 101), 2);

        // epoch interval = MAX
        assertEq(operator.getEpochFromBlock(0, 0, type(uint256).max), 0);
        assertEq(operator.getEpochFromBlock(0, 1, type(uint256).max), 0);
        assertEq(operator.getEpochFromBlock(0, type(uint256).max, type(uint256).max), 1);
    }

    function testCannotGetEpochFromBlock() public {
        // panic: division or modulo by zero
        vm.expectRevert();
        operator.getEpochFromBlock(0, 0, 0);
        vm.expectRevert();
        operator.getEpochFromBlock(0, 1, 0);
        vm.expectRevert();
        operator.getEpochFromBlock(0, 0, type(uint256).min);

        // panic: arithmetic underflow or overflow
        vm.expectRevert();
        operator.getEpochFromBlock(100, 99, 1);
        vm.expectRevert();
        operator.getEpochFromBlock(0, type(uint256).max + 1, type(uint256).max);
        vm.expectRevert();
        operator.getEpochFromBlock(0, type(uint256).min - 1, type(uint256).min);
    }

    function testGetBlockFromEpoch() public {
        // epoch interval = 1
        assertEq(operator.getBlockFromEpoch(0, 0, 1), 0);
        assertEq(operator.getBlockFromEpoch(0, 1, 1), 1);
        assertEq(operator.getBlockFromEpoch(100, 0, 1), 100);
        assertEq(operator.getBlockFromEpoch(100, 1, 1), 101);

        // epoch interval = 101
        assertEq(operator.getBlockFromEpoch(0, 0, 101), 0);
        assertEq(operator.getBlockFromEpoch(0, 1, 101), 101);
        assertEq(operator.getBlockFromEpoch(0, 2, 101), 202);

        // epoch interval = MAX
        assertEq(operator.getBlockFromEpoch(0, 0, type(uint256).max), 0);
        assertEq(operator.getBlockFromEpoch(0, 1, type(uint256).max), type(uint256).max);

        // epoch interval = MIN
        assertEq(operator.getBlockFromEpoch(0, 0, type(uint256).min), 0);
        assertEq(operator.getBlockFromEpoch(0, 1, type(uint256).min), 0);
    }

    function testCannotGetBlockFromEpoch() public {
        // panic: arithmetic underflow or overflow
        vm.expectRevert();
        operator.getBlockFromEpoch(0, 2, type(uint256).max);
    }

    //////////////////////////////
    /// Tax
    //////////////////////////////

    function testCalculateTax() public {
        vm.prank(ADMIN);
        uint256 _price = 1000;
        uint256 _taxRate = 2;
        uint256 _tokenId = operator.mintBoard(_taxRate, EPOCH_INTERVAL);
        uint256 _tax = operator.calculateTax(_tokenId, _price);
        assertEq(_tax, 2);

        vm.prank(ADMIN);
        uint256 _price1 = 1007;
        uint256 _taxRate1 = 2;
        uint256 _tokenId1 = operator.mintBoard(_taxRate1, EPOCH_INTERVAL);
        uint256 _tax1 = operator.calculateTax(_tokenId1, _price1);
        assertEq(_tax1, 2);

        vm.prank(ADMIN);
        uint256 _price2 = 0;
        uint256 _taxRate2 = 100;
        uint256 _tokenId2 = operator.mintBoard(_taxRate2, EPOCH_INTERVAL);
        uint256 _tax2 = operator.calculateTax(_tokenId2, _price2);
        assertEq(_tax2, 0);
    }

    function testCannotCalculateTax() public {
        vm.prank(ADMIN);
        uint256 _price = 1000;
        uint256 _taxRate = type(uint256).max;
        uint256 _tokenId = operator.mintBoard(_taxRate, EPOCH_INTERVAL);
        vm.expectRevert();
        operator.calculateTax(_tokenId, _price);
    }

    function testWithdrawTax(uint96 _price) public {
        vm.assume(_price > 0.001 ether);

        (uint256 _tokenId, IBillboardRegistry.Board memory _board) = _mintBoard();
        uint256 _epoch = operator.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
        uint256 _tax = operator.calculateTax(_tokenId, _price);
        uint256 _clearedAt = operator.getBlockFromEpoch(_board.startedAt, _epoch + 1, _board.epochInterval);

        // place bid with USER_A
        _placeBid(_tokenId, _epoch, USER_A, _price);

        // clear auction
        vm.roll(_clearedAt);
        operator.clearAuction(_tokenId, _epoch);

        uint256 _prevRegistryBalance = usdt.balanceOf(address(registry));
        uint256 _prevAdminBalance = usdt.balanceOf(ADMIN);
        (uint256 _taxAccumulated, uint256 _taxWithdrawn) = registry.taxTreasury(ADMIN);
        assertEq(_taxAccumulated, _tax);
        assertEq(_taxWithdrawn, 0);

        // withdraw tax
        vm.expectEmit(true, true, true, true);
        emit IBillboardRegistry.TaxWithdrawn(ADMIN, _tax);

        vm.prank(ADMIN);
        operator.withdrawTax(ADMIN);

        // check balances
        assertEq(usdt.balanceOf(address(registry)), _prevRegistryBalance - _tax);
        assertEq(usdt.balanceOf(ADMIN), _prevAdminBalance + _tax);
    }

    function testCannnotWithdrawTaxIfZero() public {
        (uint256 _taxAccumulated, uint256 _taxWithdrawn) = registry.taxTreasury(ADMIN);
        assertEq(_taxAccumulated, 0);
        assertEq(_taxWithdrawn, 0);

        vm.prank(ADMIN);
        vm.expectRevert("Zero amount");
        operator.withdrawTax(ADMIN);
    }

    //////////////////////////////
    /// ERC20 & ERC721 related
    //////////////////////////////

    function testCannotTransferToZeroAddress() public {
        (uint256 _tokenId, ) = _mintBoard();

        vm.startPrank(ADMIN);

        vm.expectRevert("ERC721: transfer to the zero address");
        registry.transferFrom(ADMIN, ZERO_ADDRESS, _tokenId);
    }

    function testCannotTransferByOperator() public {
        (uint256 _tokenId, ) = _mintBoard();

        vm.startPrank(address(operator));

        vm.expectRevert("ERC721: caller is not token owner or approved");
        registry.transferFrom(USER_B, USER_C, _tokenId);
    }

    function testSafeTransferByOperator() public {
        (uint256 _tokenId, ) = _mintBoard();

        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(ADMIN, USER_A, _tokenId);

        vm.startPrank(address(operator));
        registry.safeTransferByOperator(ADMIN, USER_A, _tokenId);
        assertEq(registry.ownerOf(_tokenId), USER_A);
    }

    function testCannotSafeTransferByAttacker() public {
        (uint256 _tokenId, ) = _mintBoard();

        vm.startPrank(ATTACKER);

        vm.expectRevert("Operator");
        registry.safeTransferByOperator(ADMIN, ATTACKER, _tokenId);
    }

    function testApproveAndTransfer() public {
        (uint256 _tokenId, ) = _mintBoard();

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
        (uint256 _tokenId, ) = _mintBoard();

        vm.stopPrank();
        vm.startPrank(ATTACKER);
        vm.expectRevert("ERC721: approve caller is not token owner or approved for all");
        registry.approve(USER_A, _tokenId);
    }

    function testGetTokenURI() public {
        (uint256 _tokenId, ) = _mintBoard();

        vm.startPrank(ADMIN);

        // new board
        string memory json = Base64.encode(
            bytes(string(abi.encodePacked('{"name": "Billboard #1", "description": "", "location": "", "image": ""}')))
        );
        assertEq(registry.tokenURI(_tokenId), string(abi.encodePacked("data:application/json;base64,", json)));

        //  set board data
        string memory _name = "name";
        string memory _description = "description";
        string memory _imageURI = "image URI";
        string memory _location = "location";
        operator.setBoard(_tokenId, _name, _description, _imageURI, _location);

        string memory newJson = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Billboard #1", "description": "description", "location": "location", "image": "image URI"}'
                    )
                )
            )
        );
        assertEq(registry.tokenURI(_tokenId), string(abi.encodePacked("data:application/json;base64,", newJson)));
    }
}
