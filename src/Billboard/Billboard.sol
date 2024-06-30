//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./BillboardRegistry.sol";
import "./IBillboard.sol";
import "./IBillboardRegistry.sol";

contract Billboard is IBillboard {
    // access control
    BillboardRegistry public immutable registry;
    address public immutable admin;

    // tokenId => address => whitelisted
    mapping(uint256 => mapping(address => bool)) public boardWhitelists;

    constructor(address token_, address payable registry_, address admin_, string memory name_, string memory symbol_) {
        require(admin_ != address(0), "Zero address");
        admin = admin_;

        // deploy operator only
        if (registry_ != address(0)) {
            registry = BillboardRegistry(registry_);
        }
        // deploy operator and registry
        else {
            registry = new BillboardRegistry(token_, address(this), name_, symbol_);
        }
    }

    //////////////////////////////
    /// Modifiers
    //////////////////////////////

    modifier isFromAdmin() {
        require(msg.sender == admin, "Admin");
        _;
    }

    modifier isFromWhitelist(uint256 tokenId_) {
        require(boardWhitelists[tokenId_][msg.sender], "Whitelist");
        _;
    }

    modifier isFromBoardCreator(uint256 tokenId_) {
        IBillboardRegistry.Board memory _board = registry.getBoard(tokenId_);
        require(_board.creator == msg.sender, "Creator");
        _;
    }

    modifier isFromBoardTenant(uint256 tokenId_) {
        require(msg.sender == registry.ownerOf(tokenId_), "Tenant");
        _;
    }

    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    /// @inheritdoc IBillboard
    function setRegistryOperator(address operator_) external isFromAdmin {
        registry.setOperator(operator_);
    }

    //////////////////////////////
    /// Access control
    //////////////////////////////

    /// @inheritdoc IBillboard
    function addToWhitelist(uint256 tokenId_, address value_) external isFromAdmin {
        boardWhitelists[tokenId_][value_] = true;
    }

    /// @inheritdoc IBillboard
    function removeFromWhitelist(uint256 tokenId_, address value_) external isFromAdmin {
        boardWhitelists[tokenId_][value_] = false;
    }

    //////////////////////////////
    /// Board
    //////////////////////////////

    /// @inheritdoc IBillboard
    function mintBoard(address to_, uint256 taxRate_, uint256 epochInterval_) external returns (uint256 tokenId) {
        tokenId = registry.newBoard(to_, taxRate_, epochInterval_);
    }

    /// @inheritdoc IBillboard
    function getBoard(uint256 tokenId_) external view returns (IBillboardRegistry.Board memory board) {
        return registry.getBoard(tokenId_);
    }

    /// @inheritdoc IBillboard

    function setBoard(
        uint256 tokenId_,
        string calldata name_,
        string calldata description_,
        string calldata imageURI_,
        string calldata location_
    ) external isFromBoardCreator(tokenId_) {
        registry.setBoard(tokenId_, name_, description_, imageURI_, location_);
    }

    //////////////////////////////
    /// Auction & Bid
    //////////////////////////////

    /// @inheritdoc IBillboard
    function placeBid(uint256 tokenId_, uint256 epoch_, uint256 price_) external payable isFromWhitelist(tokenId_) {
        _placeBid(tokenId_, epoch_, price_, "", "", false);
    }

    /// @inheritdoc IBillboard
    function placeBid(
        uint256 tokenId_,
        uint256 epoch_,
        uint256 price_,
        string calldata contentURI_,
        string calldata redirectURI_
    ) external payable isFromWhitelist(tokenId_) {
        _placeBid(tokenId_, epoch_, price_, contentURI_, redirectURI_, true);
    }

    function _placeBid(
        uint256 tokenId_,
        uint256 epoch_,
        uint256 price_,
        string memory contentURI_,
        string memory redirectURI_,
        bool hasURIs
    ) private {
        IBillboardRegistry.Board memory _board = registry.getBoard(tokenId_);
        require(_board.creator != address(0), "Board not found");

        uint256 _endedAt = this.getBlockFromEpoch(epoch_ + 1, _board.epochInterval);

        // clear auction if the auction is ended,
        if (_endedAt >= block.number) {
            _clearAuction(tokenId_, _board.creator, epoch_);
            return;
        }
        // otherwise, create new bid or update bid
        else {
            IBillboardRegistry.Bid memory _bid = registry.getBid(tokenId_, epoch_, msg.sender);

            uint256 _tax = calculateTax(tokenId_, price_);

            // create new bid
            if (_bid.createdAt == 0) {
                // transfer bid price and tax to the registry
                SafeERC20.safeTransferFrom(registry.token(), msg.sender, address(registry), price_ + _tax);

                // add new bid
                registry.newBid(tokenId_, epoch_, msg.sender, price_, _tax, contentURI_, redirectURI_);
            }
            // update bid
            else {
                require(price_ > _bid.price, "Price too low");

                // transfer diff amount to the registry
                uint256 _priceDiff = price_ - _bid.price;
                uint256 _taxDiff = _tax - _bid.tax;
                SafeERC20.safeTransferFrom(registry.token(), msg.sender, address(registry), _priceDiff + _taxDiff);

                if (hasURIs) {
                    registry.setBid(tokenId_, epoch_, msg.sender, price_, _tax, contentURI_, redirectURI_, true);
                } else {
                    registry.setBid(tokenId_, epoch_, msg.sender, price_, _tax, "", "", false);
                }
            }
        }
    }

    /// @inheritdoc IBillboard
    function clearAuction(
        uint256 tokenId_,
        uint256 epoch_
    ) public returns (address highestBidder, uint256 price, uint256 tax) {
        // revert if board not found
        IBillboardRegistry.Board memory _board = this.getBoard(tokenId_);
        require(_board.creator != address(0), "Board not found");

        // revert if auction is still running
        uint256 _endedAt = this.getBlockFromEpoch(epoch_ + 1, _board.epochInterval);
        require(block.number < _endedAt, "Auction not ended");

        return _clearAuction(tokenId_, _board.creator, epoch_);
    }

    /// @inheritdoc IBillboard
    function clearAuctions(
        uint256[] calldata tokenIds_,
        uint256[] calldata epochs_
    ) external returns (address[] memory highestBidders, uint256[] memory prices, uint256[] memory taxes) {
        uint256 _size = tokenIds_.length;
        address[] memory _highestBidders = new address[](_size);
        uint256[] memory _prices = new uint256[](_size);
        uint256[] memory _taxes = new uint256[](_size);

        for (uint256 i = 0; i < _size; i++) {
            (_highestBidders[i], _prices[i], _taxes[i]) = clearAuction(tokenIds_[i], epochs_[i]);
        }

        return (_highestBidders, _prices, _taxes);
    }

    function _clearAuction(
        uint256 tokenId_,
        address boardCreator_,
        uint256 epoch_
    ) private returns (address highestBidder, uint256 price, uint256 tax) {
        address _highestBidder = registry.higgestBidder(tokenId_, epoch_);
        IBillboardRegistry.Bid memory _highestBid = registry.getBid(tokenId_, epoch_, _highestBidder);

        // skip if auction is already cleared
        if (_highestBid.isWon) {
            return (address(0), 0, 0);
        }

        address _prevOwner = registry.ownerOf(tokenId_);

        if (_highestBid.price > 0) {
            // transfer bid price to board owner (previous tenant or creator)
            registry.transferTokenByOperator(_prevOwner, _highestBid.price);

            // transfer bid tax to board creator's tax treasury
            (uint256 _taxAccumulated, uint256 _taxWithdrawn) = registry.taxTreasury(boardCreator_);
            registry.setTaxTreasury(boardCreator_, _taxAccumulated + _highestBid.tax, _taxWithdrawn);
        }

        // transfer ownership
        registry.safeTransferByOperator(_prevOwner, _highestBidder, tokenId_);

        // mark highest bid as won
        registry.setBidWon(tokenId_, epoch_, _highestBidder, true);

        // emit AuctionCleared
        registry.emitAuctionCleared(tokenId_, epoch_, _highestBidder);

        return (_highestBidder, _highestBid.price, _highestBid.tax);
    }

    /// @inheritdoc IBillboard
    function getBid(
        uint256 tokenId_,
        uint256 epoch_,
        address bidder_
    ) external view returns (IBillboardRegistry.Bid memory bid) {
        return registry.getBid(tokenId_, epoch_, bidder_);
    }

    /// @inheritdoc IBillboard
    function getBids(
        uint256 tokenId_,
        uint256 epoch_,
        uint256 limit_,
        uint256 offset_
    ) external view returns (uint256 total, uint256 limit, uint256 offset, IBillboardRegistry.Bid[] memory bids) {
        uint256 _total = registry.getBidCount(tokenId_, epoch_);

        if (limit_ == 0) {
            return (_total, limit_, offset_, new IBillboardRegistry.Bid[](0));
        }

        if (offset_ >= _total) {
            return (_total, limit_, offset_, new IBillboardRegistry.Bid[](0));
        }

        uint256 _left = _total - offset_;
        uint256 _size = _left > limit_ ? limit_ : _left;

        IBillboardRegistry.Bid[] memory _bids = new IBillboardRegistry.Bid[](_size);

        for (uint256 i = 0; i < _size; i++) {
            address _bidder = registry.bidders(tokenId_, epoch_, offset_ + i);
            _bids[i] = registry.getBid(tokenId_, epoch_, _bidder);
        }

        return (_total, limit_, offset_, _bids);
    }

    /// @inheritdoc IBillboard
    function withdrawBid(uint256 tokenId_, uint256 epoch_) external {
        // revert if board not found
        IBillboardRegistry.Board memory _board = this.getBoard(tokenId_);
        require(_board.creator != address(0), "Board not found");

        // revert if auction is not ended
        uint256 _endedAt = this.getBlockFromEpoch(epoch_ + 1, _board.epochInterval);
        require(block.number < _endedAt, "Auction not ended");

        // revert if auction is not cleared
        address _highestBidder = registry.higgestBidder(tokenId_, epoch_);
        IBillboardRegistry.Bid memory _highestBid = registry.getBid(tokenId_, epoch_, _highestBidder);
        require(!_highestBid.isWon, "Auction not cleared");

        IBillboardRegistry.Bid memory _bid = registry.getBid(tokenId_, epoch_, msg.sender);
        uint256 amount = _bid.price + _bid.tax;

        require(_bid.createdAt != 0, "Bid not found");
        require(!_bid.isWithdrawn, "Bid already withdrawn");
        require(!_bid.isWon, "Bid already won");
        require(amount > 0, "Zero amount");

        // set bid.isWithdrawn to true first to prevent reentrancy
        registry.setBidWithdrawn(tokenId_, epoch_, msg.sender, true);

        // transfer bid price and tax back to the bidder
        registry.transferTokenByOperator(msg.sender, amount);
    }

    /// @inheritdoc IBillboard
    function getEpochFromBlock(uint256 block_, uint256 epochInterval_) public pure returns (uint256 epoch) {
        // TODO: check overflow and underflow
        return block_ / epochInterval_;
    }

    /// @inheritdoc IBillboard
    function getBlockFromEpoch(uint256 epoch_, uint256 epochInterval_) public pure returns (uint256 blockNumber) {
        // TODO: check overflow and underflow
        return epoch_ * epochInterval_;
    }

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

    /// @inheritdoc IBillboard
    function getTaxRate(uint256 tokenId_) external view returns (uint256 taxRate) {
        return registry.getBoard(tokenId_).taxRate;
    }

    function calculateTax(uint256 tokenId_, uint256 amount_) public view returns (uint256 tax) {
        tax = (amount_ * this.getTaxRate(tokenId_)) / 1000;
    }

    /// @inheritdoc IBillboard
    function withdrawTax() external returns (uint256 tax) {
        (uint256 _taxAccumulated, uint256 _taxWithdrawn) = registry.taxTreasury(msg.sender);

        uint256 amount = _taxAccumulated - _taxWithdrawn;

        require(amount > 0, "Zero amount");

        // set taxTreasury.withdrawn to taxTreasury.accumulated first
        // to prevent reentrancy
        registry.setTaxTreasury(msg.sender, _taxAccumulated, _taxAccumulated);

        // transfer tax to the owner
        registry.transferTokenByOperator(msg.sender, amount);

        // emit TaxWithdrawn
        registry.emitTaxWithdrawn(msg.sender, amount);

        return amount;
    }
}
