//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ITheSpace.sol";
import "./ITheSpaceRegistry.sol";

contract TheSpaceRegistry is ITheSpaceRegistry, ERC721Enumerable, Ownable {
    /**
     * @dev Total possible number of ERC721 token
     */
    uint256 private _totalSupply;

    /**
     * @dev ERC20 token used as currency
     */
    ERC20 public immutable currency;

    /**
     * @dev Record for all tokens (tokenId => TokenRecord).
     */
    mapping(uint256 => TokenRecord) public tokenRecord;

    /**
     * @dev Color of each token.
     */
    mapping(uint256 => uint256) public pixelColor;

    /**
     * @dev Tax configuration of market.
     */
    mapping(ConfigOptions => uint256) public taxConfig;

    /**
     * @dev Global state of tax and treasury.
     */
    TreasuryRecord public treasuryRecord;

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
        emit Config(ConfigOptions.taxRate, taxRate_);
        taxConfig[ConfigOptions.treasuryShare] = treasuryShare_;
        emit Config(ConfigOptions.treasuryShare, treasuryShare_);
        taxConfig[ConfigOptions.mintTax] = mintTax_;
        emit Config(ConfigOptions.mintTax, mintTax_);
    }

    //////////////////////////////
    /// Getters & Setters
    //////////////////////////////

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

    /// @inheritdoc ITheSpaceRegistry
    function setTotalSupply(uint256 totalSupply_) external onlyOwner {
        emit TotalSupply(_totalSupply, totalSupply_);

        _totalSupply = totalSupply_;
    }

    /// @inheritdoc ITheSpaceRegistry
    function setTaxConfig(ConfigOptions option_, uint256 value_) external onlyOwner {
        taxConfig[option_] = value_;

        emit Config(option_, value_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function setTreasuryRecord(
        uint256 accumulatedUBI_,
        uint256 accumulatedTreasury_,
        uint256 treasuryWithdrawn_
    ) external onlyOwner {
        treasuryRecord = TreasuryRecord(accumulatedUBI_, accumulatedTreasury_, treasuryWithdrawn_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function setTokenRecord(
        uint256 tokenId_,
        uint256 price_,
        uint256 lastTaxCollection_,
        uint256 ubiWithdrawn_
    ) external onlyOwner {
        tokenRecord[tokenId_] = TokenRecord(price_, lastTaxCollection_, ubiWithdrawn_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function setColor(
        uint256 tokenId_,
        uint256 color_,
        address owner_
    ) external onlyOwner {
        pixelColor[tokenId_] = color_;
        emit Color(tokenId_, color_, owner_);
    }

    //////////////////////////////
    /// Event emission
    //////////////////////////////

    /// @inheritdoc ITheSpaceRegistry
    function emitTax(
        uint256 tokenId_,
        address taxpayer_,
        uint256 amount_
    ) external onlyOwner {
        emit Tax(tokenId_, taxpayer_, amount_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function emitPrice(
        uint256 tokenId_,
        uint256 price_,
        address operator_
    ) external onlyOwner {
        emit Price(tokenId_, price_, operator_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function emitUBI(
        uint256 tokenId_,
        address recipient_,
        uint256 amount_
    ) external onlyOwner {
        emit UBI(tokenId_, recipient_, amount_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function emitTreasury(address recipient_, uint256 amount_) external onlyOwner {
        emit Treasury(recipient_, amount_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function emitDeal(
        uint256 tokenId_,
        address from_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        emit Deal(tokenId_, from_, to_, amount_);
    }

    //////////////////////////////
    /// ERC721 property related
    //////////////////////////////

    /// @inheritdoc ITheSpaceRegistry
    function mint(address to_, uint256 tokenId_) external onlyOwner {
        if (tokenId_ > _totalSupply || tokenId_ < 1) revert InvalidTokenId(1, _totalSupply);
        _safeMint(to_, tokenId_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function burn(uint256 tokenId_) external onlyOwner {
        _burn(tokenId_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function safeTransferByMarket(
        address from_,
        address to_,
        uint256 tokenId_
    ) external onlyOwner {
        _safeTransfer(from_, to_, tokenId_, "");
    }

    /// @inheritdoc ITheSpaceRegistry
    function exists(uint256 tokenId_) external view returns (bool) {
        return _exists(tokenId_);
    }

    /// @inheritdoc ITheSpaceRegistry
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
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public override(ERC721, IERC721) {
        // solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId_), "ERC721: transfer caller is not owner nor approved");

        ITheSpace market = ITheSpace(owner());

        bool success = market.beforeTransferByRegistry(tokenId_);

        if (success) {
            _safeTransfer(from_, to_, tokenId_, data_);
        }
    }

    //////////////////////////////
    /// ERC20 currency related
    //////////////////////////////

    /// @inheritdoc ITheSpaceRegistry
    function transferCurrency(address to_, uint256 amount_) external onlyOwner {
        currency.transfer(to_, amount_);
    }

    /// @inheritdoc ITheSpaceRegistry
    function transferCurrencyFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        currency.transferFrom(from_, to_, amount_);
    }
}
