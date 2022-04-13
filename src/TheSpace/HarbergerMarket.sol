//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "./IHarbergerMarket.sol";
import "./AccessRoles.sol";

/**
 * @dev Market place with Harberger tax. Market attaches one ERC20 contract as currency.
 */
contract HarbergerMarket is ERC721Enumerable, IHarbergerMarket, Multicall, AccessRoles {
    /**
     * Global setup total supply and currency address
     */

    /**
     * @dev Total possible NFTs
     */
    uint256 public _totalSupply = 1000000;

    /**
     * @dev ERC20 token used as currency
     */
    ERC20 public currency;

    /**
     * State variables for each token
     */

    /**
     * @dev Record of each token.
     * @param price Current price.
     * @param lastTaxCollection Block number of last tax collection.
     * @param ubiWithdrawn Amount of UBI been withdrawn.
     *
     * TODO: more efficient storage scheme, see: https://medium.com/@novablitz/storing-structs-is-costing-you-gas-774da988895e
     */
    struct TokenRecord {
        uint256 price;
        uint256 lastTaxCollection;
        uint256 ubiWithdrawn;
    }

    /**
     * @dev Record for all tokens.
     */
    mapping(uint256 => TokenRecord) public tokenRecord;

    /**
     * Tax related global states.
     */

    /**
     * @dev Global state of tax and treasury.
     * @param accumulatedUBI Total amount of currency allocated for UBI.
     * @param accumulatedTreasury Total amount of currency allocated for treasury.
     * @param treasuryWithdrawn Total amount of treasury been withdrawn.
     *
     * TODO: more efficient storage scheme
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
    mapping(ConfigOptions => uint256) public taxConfig;

    /**
     * @dev Create Property contract, setup attached currency contract, setup tax rate
     */
    constructor(
        string memory propertyName_,
        string memory propertySymbol_,
        address currencyAddress_,
        address admin_,
        address treasury_
    ) ERC721(propertyName_, propertySymbol_) AccessRoles(admin_, treasury_) {
        // initialize currency contract
        currency = ERC20(currencyAddress_);

        // default config
        taxConfig[ConfigOptions.taxRate] = 25;
        taxConfig[ConfigOptions.treasuryShare] = 500;
        taxConfig[ConfigOptions.mintTax] = 100;
    }

    /**
     * Override functions
     */

    /**
     * Override support interface
     */
    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override(AccessControl, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }

    /**
     * @dev See {IERC721-transferFrom}. Override to collect tax before transfer.
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public override(ERC721, IERC721) {
        if (!_isApprovedOrOwner(_msgSender(), tokenId_)) revert Unauthorized();

        bool success = _collectTax(tokenId_);

        if (success) {
            // proceed with transfer if success
            _transfer(from_, to_, tokenId_);
        } else {
            // default token if not successful
            _burn(tokenId_);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}. Override to collect tax before transfer.
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public override(ERC721, IERC721) {
        if (!_isApprovedOrOwner(_msgSender(), tokenId_)) revert Unauthorized();

        bool success = _collectTax(tokenId_);

        if (success) {
            // proceed with transfer if success
            _safeTransfer(from_, to_, tokenId_, data_);
        } else {
            // default token if not successful
            _burn(tokenId_);
        }
    }

    /**
     * @dev See {IERC20-totalSupply}. Always return total possible amount of supply, instead of current token in circulation.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * Admin only
     */

    /// @inheritdoc IHarbergerMarket
    function setTaxConfig(ConfigOptions option_, uint256 value_) external onlyRole(ADMIN_ROLE) {
        taxConfig[option_] = value_;

        emit Config(option_, value_);
    }

    /// @inheritdoc IHarbergerMarket
    function withdrawTreasury() external onlyRole(TREASURY_ROLE) {
        uint256 amount = treasuryRecord.accumulatedTreasury - treasuryRecord.treasuryWithdrawn;

        currency.transfer(msg.sender, amount);
    }

    /**
     * Read and write of token state
     */

    /// @inheritdoc IHarbergerMarket
    function getPrice(uint256 tokenId_) public view returns (uint256 price) {
        return _exists(tokenId_) ? tokenRecord[tokenId_].price : taxConfig[ConfigOptions.mintTax];
    }

    /// @inheritdoc IHarbergerMarket
    function setPrice(uint256 tokenId_, uint256 price_) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId_)) revert Unauthorized();
        if (price_ == getPrice(tokenId_)) return;

        bool success = settleTax(tokenId_);
        if (success) _setPrice(tokenId_, price_);
    }

    /// @inheritdoc IHarbergerMarket
    function getOwner(uint256 tokenId_) public view returns (address owner) {
        return _exists(tokenId_) ? ownerOf(tokenId_) : address(0);
    }

    /// @inheritdoc IHarbergerMarket
    // TODO: might need to set a minting fee to aviod repeated default and mint
    function bid(uint256 tokenId_, uint256 price_) public {
        if (_exists(tokenId_)) {
            uint256 askPrice = getPrice(tokenId_);

            // revert if price too low
            if (price_ < askPrice) revert PriceTooLow();

            address owner = ownerOf(tokenId_);

            // skip if already own
            if (owner == msg.sender) return;

            // clear tax
            bool success = _collectTax(tokenId_);

            // process with transfer
            if (success) {
                // if tax fully paid, owner get paid normally
                currency.transferFrom(msg.sender, owner, askPrice);
            } else {
                // if tax not fully paid, token is treated as defaulted and payment is collected as tax
                // otherwise an user can use two addressses to bid from each other to avoid tax
                currency.transferFrom(msg.sender, address(this), askPrice);
                _recordTax(tokenId_, msg.sender, askPrice);
            }
            _safeTransfer(owner, msg.sender, tokenId_, "");

            emit Bid(tokenId_, owner, msg.sender, askPrice);
        } else {
            if (tokenId_ > _totalSupply || tokenId_ < 1) revert InvalidTokenId(1, _totalSupply);

            // if token does not exists yet, or token is defaulted
            // mint token to current sender for free

            currency.transferFrom(msg.sender, address(this), taxConfig[ConfigOptions.mintTax]);
            _recordTax(tokenId_, msg.sender, taxConfig[ConfigOptions.mintTax]);

            _safeMint(msg.sender, tokenId_);

            // equal to bidding from address 0 with price 0
            emit Bid(tokenId_, address(0), msg.sender, 0);

            // initialize tax record and price
            tokenRecord[tokenId_].lastTaxCollection = block.number;
            _setPrice(tokenId_, price_);
        }
    }

    /**
     * Tax & UBI
     */

    /// @inheritdoc IHarbergerMarket
    function getTax(uint256 tokenId_) public view returns (uint256) {
        if (!_exists(tokenId_)) revert TokenNotExists();

        // calculate tax
        // `1000` for every `1000` blocks, `10000` for conversion from bps
        return
            (getPrice(tokenId_) *
                taxConfig[ConfigOptions.taxRate] *
                (block.number - tokenRecord[tokenId_].lastTaxCollection)) / (1000 * 10000);
    }

    /// @inheritdoc IHarbergerMarket
    function evaluateOwnership(uint256 tokenId_) public view returns (uint256 collectable, bool shouldDefault) {
        uint256 tax = getTax(tokenId_);
        if (tax > 0) {
            // calculate collectable amount
            address taxpayer = ownerOf(tokenId_);
            uint256 allowance = currency.allowance(taxpayer, address(this));
            uint256 balance = currency.balanceOf(taxpayer);
            uint256 available = allowance < balance ? allowance : balance;

            if (available > tax) {
                // can pay tax fully and do not need to be defaulted
                return (tax, false);
            } else {
                // cannot pay tax fully and need to be defaulted
                return (available, true);
            }
        } else {
            // not tax needed
            return (0, false);
        }
    }

    /**
     * @dev Collect outstanding tax for a given token, put token on tax sale if obligation not met.
     *
     * Emits a {Tax} event and a {Price} event (when properties are put on tax sale).
     */
    function _collectTax(uint256 tokenId_) private returns (bool success) {
        (uint256 collectable, bool shouldDefault) = evaluateOwnership(tokenId_);

        if (collectable > 0) {
            // collect and record tax
            address owner = ownerOf(tokenId_);
            currency.transferFrom(owner, address(this), collectable);
            _recordTax(tokenId_, owner, collectable);
        }

        return !shouldDefault;
    }

    /// @inheritdoc IHarbergerMarket
    function settleTax(uint256 tokenId_) public returns (bool success) {
        bool fullyCollected = _collectTax(tokenId_);

        if (!fullyCollected) _burn(tokenId_);

        return fullyCollected;
    }

    /**
     * @dev Update tax record and emit Tax event.
     */
    function _recordTax(
        uint256 tokenId_,
        address taxpayer,
        uint256 amount
    ) private {
        // update accumulated ubi
        treasuryRecord.accumulatedUBI += (amount * (10000 - taxConfig[ConfigOptions.treasuryShare])) / 10000;

        // update accumulated treasury
        treasuryRecord.accumulatedTreasury += (amount * taxConfig[ConfigOptions.treasuryShare]) / 10000;

        // update tax record
        tokenRecord[tokenId_].lastTaxCollection = block.number;
        emit Tax(tokenId_, taxpayer, amount);
    }

    /// @inheritdoc IHarbergerMarket
    function ubiAvailable(uint256 tokenId_) public view returns (uint256) {
        return treasuryRecord.accumulatedUBI / _totalSupply - tokenRecord[tokenId_].ubiWithdrawn;
    }

    /**
     * @dev Withdraw UBI on given token.
     */
    function withdrawUbi(uint256 tokenId_) external {
        uint256 ubi = ubiAvailable(tokenId_);

        if (ubi > 0) {
            tokenRecord[tokenId_].ubiWithdrawn += ubi;
            address recipient = ownerOf(tokenId_);
            currency.transfer(recipient, ubi);

            emit UBI(tokenId_, recipient, ubi);
        }
    }

    /**
     * @dev Internel function to set price for a token.
     */
    function _setPrice(uint256 tokenId_, uint256 price_) internal {
        // update price in tax record
        tokenRecord[tokenId_].price = price_;

        // emit events
        emit Price(tokenId_, price_, ownerOf(tokenId_));
    }
}
