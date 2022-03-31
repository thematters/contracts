//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "./AccessRoles.sol";

/**
 * @dev Market place with Harberger tax. Market attaches one ERC20 contract as currency.
 */
contract HarbergerMarket is ERC721Enumerable, Multicall, AccessRoles {
    /**
     * Override interface
     */
    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }

    /**
     * Error types
     */
    error PriceTooLow();
    error Unauthorized();
    error TokenNotExists();
    error InvalidTokenId(uint256 min, uint256 max);

    /**
     * Event types
     */

    /**
     * @dev Emitted when a token changes price.
     */
    event Price(uint256 indexed tokenId, uint256 price, address indexed owner);

    /**
     * @dev Emitted when tax configuration updates.
     */
    event Config(ConfigOptions indexed option, uint256 value);

    /**
     * @dev Emitted when tax is collected.
     */
    event Tax(uint256 indexed tokenId, uint256 amount);

    /**
     * @dev Emitted when UBI is distributed.
     */
    event UBI(uint256 indexed tokenId, uint256 amount);

    /**
     * @dev Emitted when a token is succefully bid.
     */
    event Bid(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);

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
     * @dev Record of token. Use block number to record tax collection time.
     *
     * TODO: more efficient storage scheme, see: https://medium.com/@novablitz/storing-structs-is-costing-you-gas-774da988895e
     */
    struct TokenRecord {
        uint256 price;
        uint256 lastTaxCollection;
        uint256 ubiWithdrawn;
    }

    /**
     * @dev Record of each token.
     */
    mapping(uint256 => TokenRecord) public tokenRecord;

    /**
     * Tax related global states.
     */

    /**
     * @dev Record of treasury state.
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
     * - taxRate: Tax rate in bps every 1000 blocks
     * - treasuryShare: Share to treasury in bps.
     */
    enum ConfigOptions {
        taxRate,
        treasuryShare
    }

    // Setting for tax config
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
        taxConfig[ConfigOptions.taxRate] = 10;
        taxConfig[ConfigOptions.treasuryShare] = 500;
    }

    /**
     * @dev See {IERC20-totalSupply}. Always return total possible amount of supply, instead of current token in circulation.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * Admin only
     */

    /**
     * @dev Set the tax config for current contract. ADMIN_ROLE only.
     */
    function setTaxConfig(ConfigOptions option_, uint256 value_) external onlyRole(ADMIN_ROLE) {
        taxConfig[option_] = value_;

        emit Config(option_, value_);
    }

    /**
     * @dev Withdraw available treasury. TREASURY_ROLE only.
     */
    function withdrawTreasury() external onlyRole(TREASURY_ROLE) {
        uint256 amount = treasuryRecord.accumulatedTreasury - treasuryRecord.treasuryWithdrawn;

        currency.transfer(msg.sender, amount);
    }

    /**
     * Read and write of token state
     */

    /**
     * @dev Returns the current price of an Harberger property with token id.
     */
    function getPrice(uint256 tokenId_) public view returns (uint256 price) {
        return tokenRecord[tokenId_].price;
    }

    /**
     * @dev Set the current price of an Harberger property with token id.
     *
     * Emits a {Price} event.
     */
    function setPrice(uint256 tokenId_, uint256 price_) external {
        if (!_isApprovedOrOwner(msg.sender, tokenId_)) revert Unauthorized();
        if (price_ == getPrice(tokenId_)) return;

        bool success = collectTax(tokenId_);
        if (success) _setPrice(tokenId_, price_);
    }

    /**
     * @dev Returns the current owner of an Harberger property with token id. If token does not exisit, return address(0).
     */
    function getOwner(uint256 tokenId_) public view returns (address owner) {
        return _exists(tokenId_) ? ownerOf(tokenId_) : address(0);
    }

    /**
     * @dev Purchase property with bid higher than current price. Clear tax for owner before transfer.
     */
    function bid(uint256 tokenId_, uint256 price_) external {
        if (_exists(tokenId_)) {
            // skip if already own
            address owner = ownerOf(tokenId_);
            if (owner == msg.sender) return;

            uint256 askPrice = getPrice(tokenId_);
            if (price_ < askPrice) revert PriceTooLow();

            // clear tax
            bool success = collectTax(tokenId_);

            if (success) {
                // successfully clear tax
                currency.transferFrom(msg.sender, owner, askPrice);
                _safeTransfer(owner, msg.sender, tokenId_, "");

                emit Bid(tokenId_, owner, msg.sender, askPrice);

                return;
            }
        }

        // if token does not exists yet, or token is defaulted
        // mint token to current sender for free
        if (tokenId_ > _totalSupply || tokenId_ < 1) revert InvalidTokenId(1, _totalSupply);
        _safeMint(msg.sender, tokenId_);
        // initialize tax record
        tokenRecord[tokenId_].lastTaxCollection = block.number;
    }

    /**
     * Tax & UBI
     */

    /**
     * @dev Calculate tax for a token
     */
    function getTax(uint256 tokenId_) public view returns (uint256) {
        if (!_exists(tokenId_)) revert TokenNotExists();

        // calculate tax
        // `1000` for every `1000` blocks, `10000` for conversion from bps
        return
            (getPrice(tokenId_) *
                taxConfig[ConfigOptions.taxRate] *
                (block.number - tokenRecord[tokenId_].lastTaxCollection)) / (1000 * 10000);
    }

    /**
     * @dev Calculate amount of tax that can be collected, and if token should be defaulted
     */
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
     * @dev Collect outstanding property tax for a given token, put token on tax sale if obligation not met.
     *
     * Emits a {Tax} event and a {Price} event (when properties are put on tax sale).
     */
    function collectTax(uint256 tokenId_) public returns (bool) {
        (uint256 collectable, bool shouldDefault) = evaluateOwnership(tokenId_);

        if (collectable > 0) {
            address taxpayer = ownerOf(tokenId_);
            // collect tax
            currency.transferFrom(taxpayer, address(this), collectable);
            emit Tax(tokenId_, collectable);

            // update accumulated ubi
            treasuryRecord.accumulatedUBI += (collectable * (10000 - taxConfig[ConfigOptions.treasuryShare])) / 10000;

            // update accumulated treasury
            treasuryRecord.accumulatedTreasury += (collectable * taxConfig[ConfigOptions.treasuryShare]) / 10000;

            // update tax record
            tokenRecord[tokenId_].lastTaxCollection = block.number;
        }

        if (shouldDefault) {
            // default token and return failure to fully collect tax
            _default(tokenId_);
            return false;
        } else {
            // success
            return true;
        }
    }

    /**
     * @dev UBI available for withdraw on given token.
     */
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
            currency.transfer(ownerOf(tokenId_), ubi);

            emit UBI(tokenId_, ubi);
        }
    }

    function _default(uint256 tokenId_) internal {
        _burn(tokenId_);
        _setPrice(tokenId_, 0);
    }

    function _setPrice(uint256 tokenId_, uint256 price_) internal {
        // update price in tax record
        tokenRecord[tokenId_].price = price_;

        address owner = _exists(tokenId_) ? ownerOf(tokenId_) : address(0);

        // emit events
        emit Price(tokenId_, price_, owner);
    }
}
