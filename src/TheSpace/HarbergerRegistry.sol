//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IHarbergerRegistry.sol";
import "./IHarbergerMarket.sol";

/**
 * @dev Storage contract for Harberger Market. It stores all states related to the market, and is owned by the market contract.
 * The market contract can be upgraded by changing the owner of this contract to the new market contract.
 */
contract HarbergerRegistry is IHarbergerRegistry, ERC721Enumerable, Ownable {
    /**
     * @dev Cannot transfer directly, use market to bid
     */
    error CannotTransfer(address market);

    /**
     * @dev Total possible number of ERC721 token
     */
    uint256 private _totalSupply;

    /**
     * @dev ERC20 token used as currency
     */
    ERC20 public currency;

    /**
     * @notice Record for all tokens (tokenId => TokenRecord).
     */
    mapping(uint256 => TokenRecord) public tokenRecord;

    TreasuryRecord public treasuryRecord;

    /**
     * @dev Tax configuration of market.
     */
    mapping(ConfigOptions => uint256) public taxConfig;

    /**
     * @dev Create Property contract, setup attached currency contract, setup tax rate.
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
        taxConfig[ConfigOptions.taxRate] = taxRate_;
        taxConfig[ConfigOptions.treasuryShare] = treasuryShare_;
        taxConfig[ConfigOptions.mintTax] = mintTax_;
    }

    /**
     * @notice See {IERC20-totalSupply}.
     * @dev Always return total possible amount of supply, instead of current token in circulation.
     */
    function totalSupply() public view override(ERC721Enumerable, IERC721Enumerable) returns (uint256) {
        return _totalSupply;
    }

    //////////////////////////////
    /// Setters for global variables
    //////////////////////////////

    /// @inheritdoc IHarbergerRegistry
    function setTotalSupply(uint256 totalSupply_) external onlyOwner {
        _totalSupply = totalSupply_;
    }

    /// @inheritdoc IHarbergerRegistry
    function setTaxConfig(ConfigOptions option_, uint256 value_) external onlyOwner {
        taxConfig[option_] = value_;

        emit Config(option_, value_);
    }

    /// @inheritdoc IHarbergerRegistry
    function setTreasuryRecord(
        uint256 accumulatedUBI_,
        uint256 accumulatedTreasury_,
        uint256 treasuryWithdrawn_
    ) external onlyOwner {
        treasuryRecord = TreasuryRecord(accumulatedUBI_, accumulatedTreasury_, treasuryWithdrawn_);
    }

    /// @inheritdoc IHarbergerRegistry
    function setTokenRecord(
        uint256 tokenId_,
        uint256 price_,
        uint256 lastTaxCollection_,
        uint256 ubiWithdrawn_
    ) external onlyOwner {
        tokenRecord[tokenId_] = TokenRecord(price_, lastTaxCollection_, ubiWithdrawn_);
    }

    //////////////////////////////
    /// Event emission
    //////////////////////////////

    /// @inheritdoc IHarbergerRegistry
    function emitTax(
        uint256 tokenId_,
        address taxpayer_,
        uint256 amount_
    ) external onlyOwner {
        emit Tax(tokenId_, taxpayer_, amount_);
    }

    /// @inheritdoc IHarbergerRegistry
    function emitPrice(
        uint256 tokenId_,
        uint256 price_,
        address operator_
    ) external onlyOwner {
        emit Price(tokenId_, price_, operator_);
    }

    /// @inheritdoc IHarbergerRegistry
    function emitUBI(
        uint256 tokenId_,
        address recipient_,
        uint256 amount_
    ) external onlyOwner {
        emit UBI(tokenId_, recipient_, amount_);
    }

    /// @inheritdoc IHarbergerRegistry
    function emitBid(
        uint256 tokenId_,
        address from_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        emit Bid(tokenId_, from_, to_, amount_);
    }

    //////////////////////////////
    /// ERC721 related
    //////////////////////////////

    /// @inheritdoc IHarbergerRegistry
    function mint(address to_, uint256 tokenId_) external onlyOwner {
        if (tokenId_ > _totalSupply || tokenId_ < 1) revert InvalidTokenId(1, _totalSupply);
        _safeMint(to_, tokenId_);
    }

    /// @inheritdoc IHarbergerRegistry
    function burn(uint256 tokenId_) external onlyOwner {
        _burn(tokenId_);
    }

    /// @inheritdoc IHarbergerRegistry
    function safeTransferByMarket(
        address from_,
        address to_,
        uint256 tokenId_
    ) external onlyOwner {
        _safeTransfer(from_, to_, tokenId_, "");
    }

    /// @inheritdoc IHarbergerRegistry
    function exists(uint256 tokenId_) external view returns (bool) {
        return _exists(tokenId_);
    }

    /// @inheritdoc IHarbergerRegistry
    function isApprovedOrOwner(address spender_, uint256 tokenId_) external view returns (bool) {
        return _isApprovedOrOwner(spender_, tokenId_);
    }

    /**
     * @notice See {IERC721-transferFrom}.
     * @dev Override to collect tax and set price before transfer.
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public override(ERC721, IERC721) {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    /**
     * @notice See {IERC721-safeTransferFrom}.
     * @dev Override to collect tax and set price before transfer.
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public override(ERC721, IERC721) {
        // get market contract
        IHarbergerMarket market = IHarbergerMarket(owner());

        // clear tax or default
        market.settleTax(tokenId_);

        // proceed with transfer if tax settled
        if (_exists(tokenId_)) {
            // transfer is regarded as setting price to 0, then bid for free
            // this is to prevent transfering huge tax obligation as a form of attack
            market.setPrice(tokenId_, 0);
            _safeTransfer(from_, to_, tokenId_, data_);
        }
    }

    //////////////////////////////
    /// ERC20 related
    //////////////////////////////

    /// @inheritdoc IHarbergerRegistry
    function transferCurrency(address to_, uint256 amount_) external onlyOwner {
        currency.transfer(to_, amount_);
    }

    /// @inheritdoc IHarbergerRegistry
    function transferCurrencyFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        currency.transferFrom(from_, to_, amount_);
    }
}
