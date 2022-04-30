//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IHarbergerMarket.sol";

/**
 * @dev Storage contract for Harberger Market.
 */
contract Registry is ERC721Enumerable, Ownable {
    /**
     * @dev Cannot transfer directly, use market to bid
     */
    error CannotTransfer(address market);

    /**
     * @dev Token id is out of range.
     * @param min Lower range of possible token id.
     * @param max Higher range of possible token id.
     */
    error InvalidTokenId(uint256 min, uint256 max);

    /**
     * @notice A token updated price.
     * @param tokenId Id of token that updated price.
     * @param price New price after update.
     * @param owner Token owner during price update.
     */
    event Price(uint256 indexed tokenId, uint256 price, address indexed owner);

    /**
     * @notice Global configuration is updated.
     * @param option Field of config been updated.
     * @param value New value after update.
     */
    event Config(IHarbergerMarket.ConfigOptions indexed option, uint256 value);

    /**
     * @notice Tax is collected for a token.
     * @param tokenId Id of token that has been taxed.
     * @param taxpayer user address who has paid the tax.
     * @param amount Amount of tax been collected.
     */
    event Tax(uint256 indexed tokenId, address indexed taxpayer, uint256 amount);

    /**
     * @notice UBI (universal basic income) is withdrawn for a token.
     * @param tokenId Id of token that UBI has been withdrawn for.
     * @param recipient user address who got this withdrawn UBI.
     * @param amount Amount of UBI withdrawn.
     */
    event UBI(uint256 indexed tokenId, address indexed recipient, uint256 amount);

    /**
     * @notice A token has been succefully bid.
     * @param tokenId Id of token that has been bid.
     * @param from Original owner before bid.
     * @param to New owner after bid.
     * @param amount Amount of currency used for bidding.
     */
    event Bid(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);

    //////////////////////////////
    /// Global setup total supply and currency address
    //////////////////////////////

    /**
     * @dev Total possible number of ERC721 token
     */
    uint256 private _totalSupply;

    /**
     * @dev ERC20 token used as currency
     */
    ERC20 public currency;

    //////////////////////////////
    /// State variables for each token
    //////////////////////////////

    /**
     * @dev Record of each token.
     * @param price Current price.
     * @param lastTaxCollection Block number of last tax collection.
     * @param ubiWithdrawn Amount of UBI been withdrawn.
     *
     */
    struct TokenRecord {
        uint256 price;
        uint256 lastTaxCollection;
        uint256 ubiWithdrawn;
    }

    /**
     * @notice Record for all tokens (tokenId => TokenRecord).
     */
    mapping(uint256 => TokenRecord) public tokenRecord;

    //////////////////////////////
    ///  Tax related global states
    //////////////////////////////

    /**
     * @dev Global state of tax and treasury.
     * @param accumulatedUBI Total amount of currency allocated for UBI.
     * @param accumulatedTreasury Total amount of currency allocated for treasury.
     * @param treasuryWithdrawn Total amount of treasury been withdrawn.
     *
     */
    struct TreasuryRecord {
        uint256 accumulatedUBI;
        uint256 accumulatedTreasury;
        uint256 treasuryWithdrawn;
    }

    TreasuryRecord public treasuryRecord;

    /**
     * @dev Tax configuration of market.
     */
    mapping(IHarbergerMarket.ConfigOptions => uint256) public taxConfig;

    /**
     * @dev Create Property contract, setup attached currency contract, setup tax rate
     */
    constructor(
        string memory propertyName_,
        string memory propertySymbol_,
        uint256 totalSupply_,
        uint256 taxRate_,
        uint256 treasuryShare_,
        uint256 mintTax_,
        address currencyAddress_
    ) ERC721(propertyName_, propertySymbol_) {
        // initialize total supply
        _totalSupply = totalSupply_;
        // initialize currency contract
        currency = ERC20(currencyAddress_);

        // initialize tax config
        taxConfig[IHarbergerMarket.ConfigOptions.taxRate] = taxRate_;
        taxConfig[IHarbergerMarket.ConfigOptions.treasuryShare] = treasuryShare_;
        taxConfig[IHarbergerMarket.ConfigOptions.mintTax] = mintTax_;
    }

    /**
     * @notice See {IERC20-totalSupply}.
     * @dev Always return total possible amount of supply, instead of current token in circulation.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    //////////////////////////////
    /// Setters for global variables
    //////////////////////////////

    function setTotalSupply(uint256 totalSupply_) external onlyOwner {
        _totalSupply = totalSupply_;
    }

    function setTaxConfig(IHarbergerMarket.ConfigOptions option_, uint256 value_) external onlyOwner {
        taxConfig[option_] = value_;

        emit Config(option_, value_);
    }

    function withdrawTreasury(address to) external onlyOwner {
        uint256 amount = treasuryRecord.accumulatedTreasury - treasuryRecord.treasuryWithdrawn;

        treasuryRecord.treasuryWithdrawn = treasuryRecord.accumulatedTreasury;

        currency.transfer(to, amount);
    }

    //////////////////////////////
    /// Records for each token
    //////////////////////////////

    /**
     * @notice Update tax record and emit Tax event.
     */
    function recordTax(
        uint256 tokenId_,
        address taxpayer_,
        uint256 amount_
    ) external onlyOwner {
        // update accumulated treasury
        uint256 treasuryShare = taxConfig[IHarbergerMarket.ConfigOptions.treasuryShare];
        uint256 treasuryAdded = (amount_ * treasuryShare) / 10000;
        treasuryRecord.accumulatedTreasury += treasuryAdded;

        // update accumulated ubi
        treasuryRecord.accumulatedUBI += (amount_ - treasuryAdded);

        // update tax record
        tokenRecord[tokenId_].lastTaxCollection = block.number;

        emit Tax(tokenId_, taxpayer_, amount_);
    }

    //
    function setPrice(uint256 tokenId_, uint256 price_) external onlyOwner {
        // update price in tax record
        tokenRecord[tokenId_].price = price_;

        // emit events
        emit Price(tokenId_, price_, ownerOf(tokenId_));
    }

    /**
     * @notice Withdraw UBI on given token.
     */
    function withdrawUbi(uint256 tokenId_, uint256 amount_) external {
        tokenRecord[tokenId_].ubiWithdrawn += amount_;

        address recipient = ownerOf(tokenId_);
        currency.transfer(recipient, amount_);

        emit UBI(tokenId_, recipient, amount_);
    }

    //////////////////////////////
    /// ERC721 related
    //////////////////////////////

    //////////////////////////////
    /// Market only writing operations
    //////////////////////////////

    function mint(address to_, uint256 tokenId_) external onlyOwner {
        if (tokenId_ > _totalSupply || tokenId_ < 1) revert InvalidTokenId(1, _totalSupply);
        _safeMint(to_, tokenId_);
    }

    function burn(uint256 tokenId_) external onlyOwner {
        _burn(tokenId_);
    }

    function safeTransferByMarket(
        address from_,
        address to_,
        uint256 tokenId_
    ) external onlyOwner {
        _safeTransfer(from_, to_, tokenId_, "");
    }

    function exists(uint256 tokenId_) external view returns (bool) {
        return _exists(tokenId_);
    }

    function isApprovedOrOwner(address spender_, uint256 tokenId_) external view returns (bool) {
        return _isApprovedOrOwner(spender_, tokenId_);
    }

    /**
     * @notice See {IERC721-transferFrom}.
     * @dev Override to collect tax before transfer.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public view override(ERC721) {
        revert CannotTransfer(owner());
    }

    /**
     * @notice See {IERC721-safeTransferFrom}.
     * @dev Override to collect tax before transfer.
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public view override(ERC721) {
        revert CannotTransfer(owner());
    }

    //////////////////////////////
    /// ERC20 related
    //////////////////////////////
    function transferCurrency(address to_, uint256 amount_) external onlyOwner {
        currency.transfer(to_, amount_);
    }

    function transferCurrencyFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        currency.transferFrom(from_, to_, amount_);
    }
}
