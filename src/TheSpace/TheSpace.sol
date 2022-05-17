//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ACLManager.sol";
import "./TheSpaceRegistry.sol";
import "./ITheSpaceRegistry.sol";
import "./ITheSpace.sol";

contract TheSpace is ITheSpace, Multicall, ReentrancyGuard, ACLManager {
    TheSpaceRegistry public registry;

    constructor(
        address currencyAddress_,
        address aclManager_,
        address marketAdmin_,
        address treasuryAdmin_
    ) ACLManager(aclManager_, marketAdmin_, treasuryAdmin_) {
        registry = new TheSpaceRegistry(
            "Planck", // property name
            "PLK", // property symbol
            1000000, // total supply
            75, // taxRate
            500, // treasuryShare
            1 * (10**uint256(ERC20(currencyAddress_).decimals())), // mintTax, 1 $SPACE
            currencyAddress_
        );
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId_) external view virtual returns (bool) {
        return interfaceId_ == type(ITheSpace).interfaceId;
    }

    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    /// @inheritdoc ITheSpace
    function upgradeTo(address newImplementation) external onlyRole(Role.aclManager) {
        registry.transferOwnership(newImplementation);
    }

    //////////////////////////////
    /// Configuration / Admin
    //////////////////////////////

    function setTotalSupply(uint256 totalSupply_) external onlyRole(Role.marketAdmin) {
        registry.setTotalSupply(totalSupply_);
    }

    /// @inheritdoc ITheSpace
    function setTaxConfig(ITheSpaceRegistry.ConfigOptions option_, uint256 value_) external onlyRole(Role.marketAdmin) {
        registry.setTaxConfig(option_, value_);
    }

    /// @inheritdoc ITheSpace
    function withdrawTreasury(address to_) external onlyRole(Role.treasuryAdmin) {
        (uint256 accumulatedUBI, uint256 accumulatedTreasury, uint256 treasuryWithdrawn) = registry.treasuryRecord();

        // calculate available amount and transfer
        uint256 amount = accumulatedTreasury - treasuryWithdrawn;
        registry.transferCurrency(to_, amount);
        registry.emitTreasury(to_, amount);

        // set `treasuryWithdrawn` to `accumulatedTreasury`
        registry.setTreasuryRecord(accumulatedUBI, accumulatedTreasury, accumulatedTreasury);
    }

    //////////////////////////////
    /// Pixel
    //////////////////////////////

    /// @inheritdoc ITheSpace
    function getPixel(uint256 tokenId_) external view returns (ITheSpaceRegistry.Pixel memory pixel) {
        return _getPixel(tokenId_);
    }

    function _getPixel(uint256 tokenId_) internal view returns (ITheSpaceRegistry.Pixel memory pixel) {
        (, uint256 lastTaxCollection, ) = registry.tokenRecord(tokenId_);

        pixel = ITheSpaceRegistry.Pixel(
            tokenId_,
            getPrice(tokenId_),
            lastTaxCollection,
            ubiAvailable(tokenId_),
            getOwner(tokenId_),
            registry.pixelColor(tokenId_)
        );
    }

    /// @inheritdoc ITheSpace
    function setPixel(
        uint256 tokenId_,
        uint256 bidPrice_,
        uint256 newPrice_,
        uint256 color_
    ) external {
        bid(tokenId_, bidPrice_);
        setPrice(tokenId_, newPrice_);
        _setColor(tokenId_, color_, msg.sender);
    }

    /// @inheritdoc ITheSpace
    function setColor(uint256 tokenId_, uint256 color_) public {
        if (!registry.isApprovedOrOwner(msg.sender, tokenId_)) revert Unauthorized();

        _setColor(tokenId_, color_, registry.ownerOf(tokenId_));
    }

    function _setColor(
        uint256 tokenId_,
        uint256 color_,
        address owner_
    ) internal {
        registry.setColor(tokenId_, color_, owner_);
    }

    /// @inheritdoc ITheSpace
    function getColor(uint256 tokenId) public view returns (uint256 color) {
        color = registry.pixelColor(tokenId);
    }

    /// @inheritdoc ITheSpace
    function getPixelsByOwner(
        address owner_,
        uint256 limit_,
        uint256 offset_
    )
        external
        view
        returns (
            uint256 total,
            uint256 limit,
            uint256 offset,
            ITheSpaceRegistry.Pixel[] memory pixels
        )
    {
        uint256 _total = registry.balanceOf(owner_);
        if (limit_ == 0) {
            return (_total, limit_, offset_, new ITheSpaceRegistry.Pixel[](0));
        }

        if (offset_ >= _total) {
            return (_total, limit_, offset_, new ITheSpaceRegistry.Pixel[](0));
        }
        uint256 left = _total - offset_;
        uint256 size = left > limit_ ? limit_ : left;

        ITheSpaceRegistry.Pixel[] memory _pixels = new ITheSpaceRegistry.Pixel[](size);

        for (uint256 i = 0; i < size; i++) {
            uint256 tokenId = registry.tokenOfOwnerByIndex(owner_, i + offset_);
            _pixels[i] = _getPixel(tokenId);
        }

        return (_total, limit_, offset_, _pixels);
    }

    //////////////////////////////
    /// Trading
    //////////////////////////////

    /// @inheritdoc ITheSpace
    function getPrice(uint256 tokenId_) public view returns (uint256 price) {
        return
            registry.exists(tokenId_)
                ? _getPrice(tokenId_)
                : registry.taxConfig(ITheSpaceRegistry.ConfigOptions.mintTax);
    }

    function _getPrice(uint256 tokenId_) internal view returns (uint256) {
        (uint256 price, , ) = registry.tokenRecord(tokenId_);
        return price;
    }

    /// @inheritdoc ITheSpace
    function setPrice(uint256 tokenId_, uint256 price_) public {
        if (!(registry.isApprovedOrOwner(msg.sender, tokenId_))) revert Unauthorized();
        if (price_ == _getPrice(tokenId_)) return;

        bool success = settleTax(tokenId_);
        if (success) _setPrice(tokenId_, price_);
    }

    /**
     * @dev Internal function to set price without checking
     */
    function _setPrice(uint256 tokenId_, uint256 price_) private {
        _setPrice(tokenId_, price_, registry.ownerOf(tokenId_));
    }

    function _setPrice(
        uint256 tokenId_,
        uint256 price_,
        address operator_
    ) private {
        // max price to prevent overflow of `_getTax`
        uint256 maxPrice = registry.currency().totalSupply();
        if (price_ > maxPrice) revert PriceTooHigh(maxPrice);

        (, uint256 lastTaxCollection, uint256 ubiWithdrawn) = registry.tokenRecord(tokenId_);

        registry.setTokenRecord(tokenId_, price_, lastTaxCollection, ubiWithdrawn);
        registry.emitPrice(tokenId_, price_, operator_);
    }

    /// @inheritdoc ITheSpace
    function getOwner(uint256 tokenId_) public view returns (address owner) {
        return registry.exists(tokenId_) ? registry.ownerOf(tokenId_) : address(0);
    }

    /// @inheritdoc ITheSpace
    function bid(uint256 tokenId_, uint256 price_) public nonReentrant {
        address owner = getOwner(tokenId_);
        uint256 askPrice = _getPrice(tokenId_);
        uint256 mintTax = registry.taxConfig(ITheSpaceRegistry.ConfigOptions.mintTax);

        // bid price and payee is calculated based on tax and token status
        uint256 bidPrice;

        if (registry.exists(tokenId_)) {
            // skip if already own
            if (owner == msg.sender) return;

            // clear tax
            bool success = _collectTax(tokenId_);

            // proceed with transfer
            if (success) {
                // if tax fully paid, owner get paid normally
                bidPrice = askPrice;

                // revert if price too low
                if (price_ < bidPrice) revert PriceTooLow();

                // settle ERC20 token
                registry.transferCurrencyFrom(msg.sender, owner, bidPrice);

                // settle ERC721 token
                registry.safeTransferByMarket(owner, msg.sender, tokenId_);

                // emit deal event
                registry.emitDeal(tokenId_, owner, msg.sender, bidPrice);

                // update price to ask price if difference
                if (price_ > askPrice) _setPrice(tokenId_, price_, msg.sender);

                return;
            } else {
                // if tax not fully paid, token is treated as defaulted and mint tax is collected and recorded
                registry.burn(tokenId_);
            }
        }

        // mint tax is collected and recorded
        bidPrice = mintTax;

        // revert if price too low
        if (price_ < bidPrice) revert PriceTooLow();

        // settle ERC20 token
        registry.transferCurrencyFrom(msg.sender, address(registry), bidPrice);

        // record as tax income
        _recordTax(tokenId_, msg.sender, mintTax);

        // settle ERC721 token
        registry.mint(msg.sender, tokenId_);

        // emit deal event
        registry.emitDeal(tokenId_, owner, msg.sender, bidPrice);

        // update price to ask price if difference
        if (price_ > askPrice) _setPrice(tokenId_, price_, msg.sender);
    }

    //////////////////////////////
    /// Tax & UBI
    //////////////////////////////

    /// @inheritdoc ITheSpace
    function getTax(uint256 tokenId_) public view returns (uint256) {
        if (!registry.exists(tokenId_)) revert TokenNotExists();

        return _getTax(tokenId_);
    }

    function _getTax(uint256 tokenId_) internal view returns (uint256) {
        (uint256 price, uint256 lastTaxCollection, ) = registry.tokenRecord(tokenId_);

        if (price == 0) return 0;

        uint256 taxRate = registry.taxConfig(ITheSpaceRegistry.ConfigOptions.taxRate);

        // `1000` for every `1000` blocks, `10000` for conversion from bps
        return ((price * taxRate * (block.number - lastTaxCollection)) / (1000 * 10000));
    }

    /// @inheritdoc ITheSpace
    function evaluateOwnership(uint256 tokenId_) public view returns (uint256 collectable, bool shouldDefault) {
        uint256 tax = getTax(tokenId_);

        if (tax > 0) {
            // calculate collectable amount
            address taxpayer = registry.ownerOf(tokenId_);
            uint256 allowance = registry.currency().allowance(taxpayer, address(registry));
            uint256 balance = registry.currency().balanceOf(taxpayer);
            uint256 available = allowance < balance ? allowance : balance;

            if (available >= tax) {
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
     * @notice Collect outstanding tax for a given token, put token on tax sale if obligation not met.
     * @dev Emits a {Tax} event
     * @dev Emits a {Price} event (when properties are put on tax sale).
     */
    function _collectTax(uint256 tokenId_) private returns (bool success) {
        (uint256 collectable, bool shouldDefault) = evaluateOwnership(tokenId_);

        if (collectable > 0) {
            // collect and record tax
            address owner = registry.ownerOf(tokenId_);
            registry.transferCurrencyFrom(owner, address(registry), collectable);
            _recordTax(tokenId_, owner, collectable);
        }

        return !shouldDefault;
    }

    /**
     * @notice Update tax record and emit Tax event.
     */
    function _recordTax(
        uint256 tokenId_,
        address taxpayer_,
        uint256 amount_
    ) private {
        // calculate treasury change
        uint256 treasuryShare = registry.taxConfig(ITheSpaceRegistry.ConfigOptions.treasuryShare);
        uint256 treasuryAdded = (amount_ * treasuryShare) / 10000;

        // set treasury record
        (uint256 accumulatedUBI, uint256 accumulatedTreasury, uint256 treasuryWithdrawn) = registry.treasuryRecord();
        registry.setTreasuryRecord(
            accumulatedUBI + (amount_ - treasuryAdded),
            accumulatedTreasury + treasuryAdded,
            treasuryWithdrawn
        );

        // update lastTaxCollection and emit tax event
        (uint256 price, , uint256 ubiWithdrawn) = registry.tokenRecord(tokenId_);
        registry.setTokenRecord(tokenId_, price, block.number, ubiWithdrawn);
        registry.emitTax(tokenId_, taxpayer_, amount_);
    }

    /// @inheritdoc ITheSpace
    function settleTax(uint256 tokenId_) public returns (bool success) {
        success = _collectTax(tokenId_);
        if (!success) registry.burn(tokenId_);
    }

    /// @inheritdoc ITheSpace
    function ubiAvailable(uint256 tokenId_) public view returns (uint256) {
        (uint256 accumulatedUBI, , ) = registry.treasuryRecord();
        (, , uint256 ubiWithdrawn) = registry.tokenRecord(tokenId_);

        return accumulatedUBI / registry.totalSupply() - ubiWithdrawn;
    }

    /// @inheritdoc ITheSpace
    function withdrawUbi(uint256 tokenId_) external {
        uint256 amount = ubiAvailable(tokenId_);

        if (amount > 0) {
            // transfer
            address recipient = registry.ownerOf(tokenId_);
            registry.transferCurrency(recipient, amount);

            // record
            (uint256 price, uint256 lastTaxCollection, uint256 ubiWithdrawn) = registry.tokenRecord(tokenId_);
            registry.setTokenRecord(tokenId_, price, lastTaxCollection, ubiWithdrawn + amount);

            // emit event
            registry.emitUBI(tokenId_, recipient, amount);
        }
    }

    //////////////////////////////
    /// Registry backcall
    //////////////////////////////

    /// @inheritdoc ITheSpace
    function beforeTransferByRegistry(uint256 tokenId_) external returns (bool success) {
        if (msg.sender != address(registry)) revert Unauthorized();

        // clear tax or default
        settleTax(tokenId_);

        // proceed with transfer if tax settled
        if (registry.exists(tokenId_)) {
            // transfer is regarded as setting price to 0, then bid for free
            // this is to prevent transferring huge tax obligation as a form of attack
            _setPrice(tokenId_, 0);

            success = true;
        } else {
            success = false;
        }
    }
}
