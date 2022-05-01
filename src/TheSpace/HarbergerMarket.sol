//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Multicall.sol";

import "./ACLManager.sol";
import "./HarbergerRegistry.sol";
import "./IHarbergerRegistry.sol";
import "./IHarbergerMarket.sol";

/**
 * @dev Market place with Harberger tax. This contract holds the logic of market place, while read from and write into {HarbergerRegistry}, which is the storage contact.
 * This contract owns a {HarbergerRegistry} contract for storage, and can be updated by transfering ownership to a new Harberger Market contract.
 */
contract HarbergerMarket is IHarbergerMarket, Multicall, ACLManager {
    HarbergerRegistry public registry;

    /**
     * @dev Create Property contract, setup attached currency contract, setup tax rate
     */
    constructor(
        string memory propertyName_,
        string memory propertySymbol_,
        uint256 totalSupply_,
        address currencyAddress_,
        address aclManager_,
        address marketAdmin_,
        address treasuryAdmin_
    ) ACLManager(aclManager_, marketAdmin_, treasuryAdmin_) {
        registry = new HarbergerRegistry(
            propertyName_,
            propertySymbol_,
            totalSupply_,
            75, // taxRate
            500, // treasuryShare
            0, // mintTax
            currencyAddress_
        );
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId_) external view virtual returns (bool) {
        return interfaceId_ == type(IHarbergerMarket).interfaceId;
    }

    /**
     * @notice switch logic contract to another one.
     * @param newContract address of new logic contract.
     */
    function upgradeContract(address newContract) external onlyRole(Role.aclManager) {
        registry.transferOwnership(newContract);
    }

    //////////////////////////////
    /// Role only
    //////////////////////////////

    /// @inheritdoc IHarbergerMarket
    function setTaxConfig(IHarbergerRegistry.ConfigOptions option_, uint256 value_)
        external
        onlyRole(Role.marketAdmin)
    {
        registry.setTaxConfig(option_, value_);
    }

    /// @inheritdoc IHarbergerMarket
    function withdrawTreasury(address to_) external onlyRole(Role.treasuryAdmin) {
        (uint256 accumulatedUBI, uint256 accumulatedTreasury, uint256 treasuryWithdrawn) = registry.treasuryRecord();

        // calculate available amount and transfer
        uint256 amount = accumulatedTreasury - treasuryWithdrawn;
        registry.transferCurrency(to_, amount);

        // set `treasuryWithdrawn` to `accumulatedTreasury`
        registry.setTreasuryRecord(accumulatedUBI, accumulatedTreasury, accumulatedTreasury);
    }

    //////////////////////////////
    /// Read and write of token state
    //////////////////////////////

    /// @inheritdoc IHarbergerMarket
    function getPrice(uint256 tokenId_) public view returns (uint256 price) {
        return
            registry.exists(tokenId_)
                ? _getPrice(tokenId_)
                : registry.taxConfig(IHarbergerRegistry.ConfigOptions.mintTax);
    }

    function _getPrice(uint256 tokenId_) internal view returns (uint256) {
        (uint256 price, , ) = registry.tokenRecord(tokenId_);
        return price;
    }

    /// @inheritdoc IHarbergerMarket
    function setPrice(uint256 tokenId_, uint256 price_) public {
        // approved operator or registry (which needs to set price before transfer token)
        if (!(registry.isApprovedOrOwner(msg.sender, tokenId_) || msg.sender == address(registry)))
            revert Unauthorized();
        if (price_ == _getPrice(tokenId_)) return;

        bool success = settleTax(tokenId_);
        if (success) _setPrice(tokenId_, price_);
    }

    /**
     * @dev Internal function to set price without checking
     */
    function _setPrice(uint256 tokenId_, uint256 price_) private {
        if (price_ > registry.currency().totalSupply()) revert PriceTooHigh();
        (, uint256 lastTaxCollection, uint256 ubiWithdrawn) = registry.tokenRecord(tokenId_);

        registry.setTokenRecord(tokenId_, price_, lastTaxCollection, ubiWithdrawn);
    }

    /// @inheritdoc IHarbergerMarket
    function getOwner(uint256 tokenId_) public view returns (address owner) {
        return registry.exists(tokenId_) ? registry.ownerOf(tokenId_) : address(0);
    }

    /// @inheritdoc IHarbergerMarket
    function bid(uint256 tokenId_, uint256 price_) public {
        address owner = getOwner(tokenId_);
        uint256 askPrice = _getPrice(tokenId_);
        uint256 mintTax = registry.taxConfig(IHarbergerRegistry.ConfigOptions.mintTax);

        // bid price and payee is calculated based on tax and token status
        uint256 bidPrice;
        address payee;

        if (registry.exists(tokenId_)) {
            // skip if already own
            if (owner == msg.sender) return;

            // clear tax
            bool success = _collectTax(tokenId_);

            // process with transfer
            if (success) {
                // if tax fully paid, owner get paid normally
                bidPrice = askPrice;
                payee = owner;
            } else {
                // if tax not fully paid, token is treated as defaulted and mint tax is collected and recorded
                bidPrice = mintTax;
                payee = address(registry);
                _recordTax(tokenId_, msg.sender, mintTax);
            }

            // settle ERC721 token
            registry.safeTransferByMarket(owner, msg.sender, tokenId_);
        } else {
            // int tax is collected and recorded
            bidPrice = mintTax;
            payee = address(registry);
            _recordTax(tokenId_, msg.sender, mintTax);

            // settle ERC721 token
            registry.mint(msg.sender, tokenId_);
        }

        // revert if price too low
        if (price_ < bidPrice) revert PriceTooLow();

        // settle ERC20 token
        registry.transferCurrencyFrom(msg.sender, payee, bidPrice);
        // emit bid event
        registry.emitBid(tokenId_, owner, msg.sender, bidPrice);

        // update price to ask price if difference
        if (price_ > askPrice) _setPrice(tokenId_, price_);
    }

    //////////////////////////////
    /// Tax & UBI
    //////////////////////////////

    /// @inheritdoc IHarbergerMarket
    function getTax(uint256 tokenId_) public view returns (uint256) {
        if (!registry.exists(tokenId_)) revert TokenNotExists();

        return _getTax(tokenId_);
    }

    function _getTax(uint256 tokenId_) internal view returns (uint256) {
        (uint256 price, uint256 lastTaxCollection, ) = registry.tokenRecord(tokenId_);

        if (price == 0) return 0;

        uint256 taxRate = registry.taxConfig(IHarbergerRegistry.ConfigOptions.taxRate);

        // `1000` for every `1000` blocks, `10000` for conversion from bps
        return ((price * taxRate * (block.number - lastTaxCollection)) / (1000 * 10000));
    }

    /// @inheritdoc IHarbergerMarket
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
        uint256 treasuryShare = registry.taxConfig(IHarbergerRegistry.ConfigOptions.treasuryShare);
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

    /// @inheritdoc IHarbergerMarket
    function settleTax(uint256 tokenId_) public returns (bool success) {
        success = _collectTax(tokenId_);
        if (!success) registry.burn(tokenId_);
    }

    /// @inheritdoc IHarbergerMarket
    function ubiAvailable(uint256 tokenId_) public view returns (uint256) {
        (uint256 accumulatedUBI, , ) = registry.treasuryRecord();
        (, , uint256 ubiWithdrawn) = registry.tokenRecord(tokenId_);

        return accumulatedUBI / registry.totalSupply() - ubiWithdrawn;
    }

    /**
     * @notice Withdraw UBI on given token.
     */
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
}
