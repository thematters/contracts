//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./BaseHarbergerMarket.t.sol";

contract HarbergerMarketTest is BaseHarbergerMarket {
    /**
     * Total Supply
     */
    function testTotalSupply() public {
        assertGt(registry.totalSupply(), 0);
    }

    function testSetTotalSupply() public {}

    function testCannotSetTotalSupplyByAttacker() public {}

    /**
     * @dev Config
     */
    function testGetConfig() public {
        assertGe(registry.taxConfig(CONFIG_TAX_RATE), 0);
        assertGe(registry.taxConfig(CONFIG_TREASURY_SHARE), 0);
        assertGe(registry.taxConfig(CONFIG_MINT_TAX), 0);
    }

    function testCannotSetConfigByAttacker() public {
        vm.expectRevert(abi.encodeWithSignature("RoleRequired(uint8)", ROLE_MARKET_ADMIN));

        vm.stopPrank();
        vm.prank(ATTACKER);
        thespace.setTaxConfig(CONFIG_TAX_RATE, 1000);
    }

    function testSetTaxRate() public {
        // set tax rate
        uint256 taxRate = 1000;
        vm.prank(MARKET_ADMIN);
        thespace.setTaxConfig(CONFIG_TAX_RATE, taxRate);

        // bid a token
        _bid();

        // roll block.number and check tax
        uint256 blockRollsTo = block.number + TAX_WINDOW;
        (, uint256 lastTaxCollection, ) = registry.tokenRecord(PIXEL_ID);
        uint256 tax = (PIXEL_PRICE * taxRate * (blockRollsTo - lastTaxCollection)) / (1000 * 10000);
        vm.roll(blockRollsTo);
        assertEq(thespace.getTax(PIXEL_ID), tax);

        // change tax rate and recheck
        uint256 newTaxRate = 10;
        vm.prank(MARKET_ADMIN);
        thespace.setTaxConfig(CONFIG_TAX_RATE, newTaxRate);
        uint256 newTax = (PIXEL_PRICE * newTaxRate * (blockRollsTo - lastTaxCollection)) / (1000 * 10000);
        vm.roll(blockRollsTo);
        assertEq(thespace.getTax(PIXEL_ID), newTax);

        // zero tax
        vm.prank(MARKET_ADMIN);
        thespace.setTaxConfig(CONFIG_TAX_RATE, 0);
        vm.roll(blockRollsTo);
        assertEq(thespace.getTax(PIXEL_ID), 0);
    }

    function testSetTreasuryShare() public {
        // set treasury share
        uint256 share = 1000;
        vm.prank(MARKET_ADMIN);
        thespace.setTaxConfig(CONFIG_TREASURY_SHARE, share);

        // bid a token
        _bid();
        _rollBlock();

        // check treasury share
        uint256 tax = thespace.getTax(PIXEL_ID);
        (, uint256 prevTreasury, ) = registry.treasuryRecord();
        uint256 expectTreasury = prevTreasury + ((tax * share) / 10000);

        thespace.settleTax(PIXEL_ID);

        (, uint256 newTreasury, ) = registry.treasuryRecord();
        assertEq(newTreasury, expectTreasury);
        assertGt(newTreasury, 0);
    }

    function testSetMintTax() public {
        // set mint tax
        uint256 mintTax = 50 * (10**uint256(currency.decimals()));
        vm.prank(MARKET_ADMIN);
        thespace.setTaxConfig(CONFIG_MINT_TAX, mintTax);

        // bid a token with mint tax as amount
        uint256 prevBalance = currency.balanceOf(PIXEL_OWNER);
        _bid(mintTax);
        assertEq(currency.balanceOf(PIXEL_OWNER), prevBalance - mintTax);
    }

    function testWithdrawTreasury() public {
        // bid a token
        _bid();

        // collect tax
        _rollBlock();
        thespace.settleTax(PIXEL_ID);

        uint256 prevTreasuryBalance = currency.balanceOf(TREASURY);
        uint256 prevContractBalance = currency.balanceOf(address(registry));
        (, uint256 accumulatedTreasury, uint256 treasuryWithdrawn) = registry.treasuryRecord();
        uint256 amount = accumulatedTreasury - treasuryWithdrawn;

        // withdraw treasury
        vm.prank(TREASURY_ADMIN);
        thespace.withdrawTreasury(TREASURY);

        // check treasury balance
        assertEq(currency.balanceOf(TREASURY), prevTreasuryBalance + amount);
        (, , uint256 newTreasuryWithdrawn) = registry.treasuryRecord();
        assertEq(newTreasuryWithdrawn, accumulatedTreasury);

        // check contract balance
        assertEq(currency.balanceOf(address(registry)), prevContractBalance - amount);
    }

    /**
     * @dev Price
     */
    function testGetPixelPrice() public {
        _bid();
        assertEq(thespace.getPrice(PIXEL_ID), PIXEL_PRICE);
    }

    function testGetNonExistingPixelPrice() public {
        uint256 mintTax = registry.taxConfig(CONFIG_MINT_TAX);
        assertEq(thespace.getPrice(PIXEL_ID + 1), mintTax);
    }

    function testSetPixelPrice(uint256 price) public {
        vm.assume(price <= registry.currency().totalSupply());

        // bid a token and set price
        _bid(PIXEL_PRICE, price);
        assertEq(thespace.getPrice(PIXEL_ID), price);
    }

    function testSetPixelPriceByOperator(uint256 price) public {
        vm.assume(price <= registry.currency().totalSupply());

        // bid a token and set price
        _bid();

        // approve pixel to operator
        vm.prank(PIXEL_OWNER);
        registry.approve(OPERATOR, PIXEL_ID);

        // set price
        vm.prank(OPERATOR);
        thespace.setPrice(PIXEL_ID, price);
        assertEq(thespace.getPrice(PIXEL_ID), price);
    }

    function testCannotSetPriceByNonOwner() public {
        // bid a token
        _bid();

        // someone tries to set price
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        vm.prank(ATTACKER);
        thespace.setPrice(PIXEL_ID, PIXEL_PRICE);
    }

    function testSetPriceTooHigh() public {
        _bid();

        uint256 newPrice = registry.currency().totalSupply() + 1;

        vm.expectRevert(abi.encodeWithSignature("PriceTooHigh()"));
        vm.prank(PIXEL_OWNER);
        thespace.setPrice(PIXEL_ID, newPrice);
    }

    /**
     * @dev Owner
     */
    function testGetOwner() public {
        _bid();
        assertEq(thespace.getOwner(PIXEL_ID), PIXEL_OWNER);
    }

    function testGetOwnerOfNonExistingToken() public {
        assertEq(thespace.getOwner(PIXEL_ID), address(0));
    }

    /**
     * @dev Bid
     */
    function testBidNewToken() public {
        _bid();

        assertEq(registry.balanceOf(PIXEL_OWNER), 1);

        // check price: bid a new pixel will set the price
        assertEq(thespace.getPrice(PIXEL_ID), PIXEL_PRICE);
    }

    function testBidExistingToken() public {
        // PIXEL_OWNER bids a pixel
        _bid();

        // PIXEL_OWNER_1 bids a pixel from PIXEL_OWNER
        uint256 newBidPrice = PIXEL_PRICE + 1000;
        _bidAs(PIXEL_OWNER_1, newBidPrice);

        // check balance
        assertEq(registry.balanceOf(PIXEL_OWNER), 0);
        assertEq(registry.balanceOf(PIXEL_OWNER_1), 1);

        // check price: bid a existing pixel with higher bid price should update the price
        assertEq(thespace.getPrice(PIXEL_ID), newBidPrice);
    }

    function testBatchBid() public {
        bytes[] memory data = new bytes[](3);

        // bid PIXEL_ID as PIXEL_OWNER
        _bid();

        data[0] = abi.encodeWithSignature("bid(uint256,uint256)", PIXEL_ID, PIXEL_PRICE);
        data[1] = abi.encodeWithSignature("bid(uint256,uint256)", PIXEL_ID + 1, PIXEL_PRICE);
        data[2] = abi.encodeWithSignature("bid(uint256,uint256)", PIXEL_ID + 2, PIXEL_PRICE);

        vm.prank(PIXEL_OWNER_1);
        thespace.multicall(data);

        assertEq(thespace.getOwner(PIXEL_ID), PIXEL_OWNER_1);
        assertEq(thespace.getOwner(PIXEL_ID + 1), PIXEL_OWNER_1);
        assertEq(thespace.getOwner(PIXEL_ID + 2), PIXEL_OWNER_1);
    }

    function testBidDefaultedToken() public {
        // bid a token and set a high price
        _bid(PIXEL_PRICE, registry.currency().totalSupply());

        // check tax is greater than balance
        _rollBlock();
        uint256 tax = thespace.getTax(PIXEL_ID);
        assertGt(tax, registry.balanceOf(PIXEL_OWNER_1));
    }

    function testCannotBidOutBoundTokens() public {
        uint256 totalSupply = registry.totalSupply();

        // oversupply id
        vm.expectRevert(abi.encodeWithSignature("InvalidTokenId(uint256,uint256)", 1, totalSupply));
        thespace.bid(totalSupply + 1, PIXEL_PRICE);

        // zero id
        vm.expectRevert(abi.encodeWithSignature("InvalidTokenId(uint256,uint256)", 1, totalSupply));
        thespace.bid(0, PIXEL_PRICE);
    }

    function testCannotBidPriceTooLow() public {
        // bid and set price
        _bid(PIXEL_PRICE, PIXEL_PRICE);

        // price too low to bid a existing token
        vm.expectRevert(abi.encodeWithSignature("PriceTooLow()"));
        _bidAs(PIXEL_OWNER_1, PIXEL_PRICE - 1);

        // price too low to bid a non-existing token
        uint256 mintTax = 50 * (10**uint256(currency.decimals()));
        vm.prank(MARKET_ADMIN);
        thespace.setTaxConfig(CONFIG_MINT_TAX, mintTax);

        vm.expectRevert(abi.encodeWithSignature("PriceTooLow()"));
        _bidAs(PIXEL_OWNER_1, mintTax - 1);
    }

    function testCannotBidExceedAllowance() public {
        // set mint tax
        uint256 mintTax = 50 * (10**uint256(currency.decimals()));
        vm.prank(MARKET_ADMIN);
        thespace.setTaxConfig(CONFIG_MINT_TAX, mintTax);

        // revoke currency approval
        vm.prank(PIXEL_OWNER);
        currency.approve(address(registry), 0);

        // bid a pixel
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        _bid();
    }

    /**
     * @dev Ownership & Tax
     */
    function testTokenShouldBeDefaulted() public {
        // bid and set price
        _bid(PIXEL_PRICE, PIXEL_PRICE);

        vm.startPrank(PIXEL_OWNER);
        _rollBlock();
        uint256 tax = thespace.getTax(PIXEL_ID);

        // check if token should be defaulted
        currency.approve(address(registry), tax - 1);
        (, bool shouldDefault) = thespace.evaluateOwnership(PIXEL_ID);
        assertTrue(shouldDefault);

        vm.stopPrank();
    }

    function testCollectableTax() public {
        // bid and set price
        _bid(PIXEL_PRICE, PIXEL_PRICE);

        vm.startPrank(PIXEL_OWNER);
        _rollBlock();
        uint256 tax = thespace.getTax(PIXEL_ID);

        // tax can be fully collected
        (uint256 collectableTax, bool shouldDefault) = thespace.evaluateOwnership(PIXEL_ID);
        assertEq(collectableTax, tax);
        assertFalse(shouldDefault);

        // tax can't be fully collected
        currency.approve(address(registry), tax - 1);
        (uint256 collectableTax2, bool shouldDefault2) = thespace.evaluateOwnership(PIXEL_ID);
        assertLt(collectableTax2, tax);
        assertTrue(shouldDefault2);

        vm.stopPrank();
    }

    function testDefault() public {
        // bid and set price
        _bid(PIXEL_PRICE, PIXEL_PRICE);

        _rollBlock();

        vm.startPrank(PIXEL_OWNER);
        currency.approve(address(registry), 0);
        thespace.settleTax(PIXEL_ID);
        assertEq(registry.balanceOf(PIXEL_OWNER), 0);
        vm.stopPrank();
    }

    function testGetTax() public {
        uint256 blockRollsTo = block.number + TAX_WINDOW;
        uint256 taxRate = registry.taxConfig(CONFIG_TAX_RATE);

        // bid and set price
        _bid(PIXEL_PRICE, PIXEL_PRICE);
        vm.roll(blockRollsTo);

        (, uint256 lastTaxCollection, ) = registry.tokenRecord(PIXEL_ID);
        uint256 tax = (PIXEL_PRICE * taxRate * (blockRollsTo - lastTaxCollection)) / (1000 * 10000);
        assertEq(thespace.getTax(PIXEL_ID), tax);
        // zero price
        _bidAs(PIXEL_OWNER_1, PIXEL_PRICE, 0);
        vm.roll(block.number + TAX_WINDOW);
        assertEq(thespace.getTax(PIXEL_ID), 0);
    }

    function testCannotGetTaxWithNonExistingToken() public {
        vm.expectRevert(abi.encodeWithSignature("TokenNotExists()"));
        thespace.getTax(0);
    }

    function testSettleTax() public {
        // bid and set price
        _bid(PIXEL_PRICE, PIXEL_PRICE);

        uint256 blockRollsTo = block.number + TAX_WINDOW;
        vm.roll(blockRollsTo);

        (uint256 prevUBI, uint256 prevTreasury, ) = registry.treasuryRecord();
        uint256 tax = thespace.getTax(PIXEL_ID);

        vm.expectEmit(true, true, true, false);
        emit Tax(PIXEL_ID, PIXEL_OWNER, tax);

        thespace.settleTax(PIXEL_ID);

        // check tax
        (uint256 newUBI, uint256 newTreasury, ) = registry.treasuryRecord();
        assertEq(newUBI + newTreasury, tax + prevUBI + prevTreasury);

        // check lastTaxCollection
        (, uint256 lastTaxCollection, ) = registry.tokenRecord(PIXEL_ID);
        assertEq(lastTaxCollection, blockRollsTo);
    }

    /**
     * @dev UBI
     */
    function testWithdrawUBI() public {
        uint256 newBidPrice = PIXEL_PRICE + 1000;
        _bidAs(PIXEL_OWNER_1, PIXEL_PRICE, newBidPrice);

        //collect tax
        _rollBlock();
        thespace.settleTax(PIXEL_ID);

        // check UBI
        uint256 ubi = thespace.ubiAvailable(PIXEL_ID);
        assertGt(ubi, 0);

        //  withdraw UBI
        uint256 prevBalance = currency.balanceOf(PIXEL_OWNER_1);
        vm.prank(PIXEL_OWNER_1);
        thespace.withdrawUbi(PIXEL_ID);
        assertEq(currency.balanceOf(PIXEL_OWNER_1), prevBalance + ubi);

        // check UBI
        assertEq(thespace.ubiAvailable(PIXEL_ID), 0);
    }

    /**
     * @dev Trasfer
     */
    function testCannotTransferFromIfDefault() public {
        // bid and set price
        _bid(PIXEL_PRICE, PIXEL_PRICE);

        _rollBlock();

        vm.startPrank(PIXEL_OWNER);
        currency.approve(address(registry), 0);

        registry.transferFrom(PIXEL_OWNER, PIXEL_OWNER_1, PIXEL_ID);

        assertEq(thespace.getOwner(PIXEL_ID), address(0));
        vm.stopPrank();
    }

    function testCanTransferFromIfSettleTax() public {
        // bid and set price
        _bid(PIXEL_PRICE, PIXEL_PRICE);

        _rollBlock();

        vm.startPrank(PIXEL_OWNER);

        registry.transferFrom(PIXEL_OWNER, PIXEL_OWNER_1, PIXEL_ID);

        assertEq(thespace.getOwner(PIXEL_ID), PIXEL_OWNER_1);
        vm.stopPrank();
    }
}
