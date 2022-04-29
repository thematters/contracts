//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./BaseHarbergerMarket.t.sol";

contract HarbergerMarketTest is BaseHarbergerMarket {
    function _bid() internal {
        vm.prank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, PIXEL_PRICE);
    }

    function _bid(uint256 bidPrice) internal {
        vm.prank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, bidPrice);
    }

    function _bid(uint256 bidPrice, uint256 newPrice) internal {
        vm.startPrank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, bidPrice);
        thespace.setPrice(PIXEL_ID, newPrice);
        vm.stopPrank();
    }

    function _bidThis(uint256 tokenId, uint256 bidPrice) internal {
        vm.prank(PIXEL_OWNER);
        thespace.bid(tokenId, bidPrice);
    }

    /**
     * Total Supply
     */
    function testTotalSupply() public {
        assertGt(thespace.totalSupply(), 0);
    }

    function testSetTotalSupply() public {}

    function testCannotSetTotalSupplyByAttacker() public {}

    /**
     * @dev Config
     */
    function testGetConfig() public {
        assertGe(thespace.taxConfig(CONFIG_TAX_RATE), 0);
        assertGe(thespace.taxConfig(CONFIG_TREASURY_SHARE), 0);
        assertGe(thespace.taxConfig(CONFIG_MINT_TAX), 0);
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
        (, uint256 lastTaxCollection, ) = thespace.tokenRecord(PIXEL_ID);
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
        (, uint256 prevTreasury, ) = thespace.treasuryRecord();
        uint256 expectTreasury = prevTreasury + ((tax * share) / 10000);

        thespace.settleTax(PIXEL_ID);

        (, uint256 newTreasury, ) = thespace.treasuryRecord();
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
        uint256 prevContractBalance = currency.balanceOf(address(thespace));
        (, uint256 accumulatedTreasury, uint256 treasuryWithdrawn) = thespace.treasuryRecord();
        uint256 amount = accumulatedTreasury - treasuryWithdrawn;

        // withdraw treasury
        vm.prank(TREASURY_ADMIN);
        thespace.withdrawTreasury(TREASURY);

        // check treasury balance
        assertEq(currency.balanceOf(TREASURY), prevTreasuryBalance + amount);
        (, , uint256 newTreasuryWithdrawn) = thespace.treasuryRecord();
        assertEq(newTreasuryWithdrawn, accumulatedTreasury);

        // check contract balance
        assertEq(currency.balanceOf(address(thespace)), prevContractBalance - amount);
    }

    /**
     * @dev Price
     */
    function testGetPixelPrice() public {
        // bid a token
        _bid();

        assertEq(thespace.getPrice(PIXEL_ID), PIXEL_PRICE);
    }

    function testGetNonExistingPixelPrice() public {
        uint256 mintTax = thespace.taxConfig(CONFIG_MINT_TAX);
        assertEq(thespace.getPrice(PIXEL_ID + 1), mintTax);
    }

    function testSetPixelPrice(uint256 price) public {
        // bid a token and set price
        _bid(PIXEL_PRICE, price);

        assertEq(thespace.getPrice(PIXEL_ID), price);
    }

    function testSetPixelPriceByOperator(uint256 price) public {
        // bid a token and set price
        _bid();

        // approve pixel to operator
        vm.prank(PIXEL_OWNER);
        thespace.approve(OPERATOR, PIXEL_ID);

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

        assertEq(thespace.balanceOf(PIXEL_OWNER), 1);

        // check price: bid a new pixel will set the price
        assertEq(thespace.getPrice(PIXEL_ID), PIXEL_PRICE);
    }

    function testBidExistingToken() public {
        // PIXEL_OWNER bids a pixel
        _bid();

        // PIXEL_OWNER_1 bids a pixel from PIXEL_OWNER
        uint256 newBidPrice = PIXEL_PRICE + 1000;
        vm.prank(PIXEL_OWNER_1);
        thespace.bid(PIXEL_ID, newBidPrice);

        // check balance
        assertEq(thespace.balanceOf(PIXEL_OWNER), 0);
        assertEq(thespace.balanceOf(PIXEL_OWNER_1), 1);

        // check price: bid a existing pixel won't change the price
        assertEq(thespace.getPrice(PIXEL_ID), PIXEL_PRICE);
    }

    function testBidDefaultedToken() public {
        // vm.stopPrank();
        // // bid a token
        // vm.startPrank(PIXEL_OWNER);
        // thespace.bid(PIXEL_ID, PIXEL_PRICE);
        // // set a high price
        // thespace.setPrice(PIXEL_ID, type(uint256).max);
        // vm.stopPrank();
        // check tax is greater than balance
        // _rollBlock();
        // uint256 tax = thespace.getTax(PIXEL_ID);
        // assertGt(tax, thespace.balanceOf(PIXEL_OWNER_1));
    }

    function testCannotBidOutBoundTokens() public {
        uint256 totalSupply = thespace.totalSupply();

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
        vm.prank(PIXEL_OWNER_1);
        thespace.bid(PIXEL_ID, PIXEL_PRICE - 1);

        // price too low to bid a non-existing token
        uint256 mintTax = 50 * (10**uint256(currency.decimals()));
        vm.prank(MARKET_ADMIN);
        thespace.setTaxConfig(CONFIG_MINT_TAX, mintTax);

        vm.expectRevert(abi.encodeWithSignature("PriceTooLow()"));
        vm.prank(PIXEL_OWNER_1);
        thespace.bid(PIXEL_ID, mintTax - 1);
    }

    function testCannotBidExceedAllowance() public {
        // revoke currency approval
        vm.prank(PIXEL_OWNER);
        currency.approve(address(thespace), 0);

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
        currency.approve(address(thespace), tax - 1);
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
        currency.approve(address(thespace), tax - 1);
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
        currency.approve(address(thespace), 0);
        thespace.settleTax(PIXEL_ID);
        assertEq(thespace.balanceOf(PIXEL_OWNER), 0);
        vm.stopPrank();
    }

    function testGetTax() public {
        uint256 blockRollsTo = block.number + TAX_WINDOW;
        uint256 taxRate = thespace.taxConfig(CONFIG_TAX_RATE);

        // bid and set price
        _bid(PIXEL_PRICE, PIXEL_PRICE);
        vm.roll(blockRollsTo);

        (, uint256 lastTaxCollection, ) = thespace.tokenRecord(PIXEL_ID);
        uint256 tax = (PIXEL_PRICE * taxRate * (blockRollsTo - lastTaxCollection)) / (1000 * 10000);
        assertEq(thespace.getTax(PIXEL_ID), tax);

        // zero price
        _bid(PIXEL_PRICE, 0);
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

        (uint256 prevUBI, uint256 prevTreasury, ) = thespace.treasuryRecord();
        uint256 tax = thespace.getTax(PIXEL_ID);

        vm.expectEmit(true, true, true, false);
        emit Tax(PIXEL_ID, PIXEL_OWNER, tax);

        thespace.settleTax(PIXEL_ID);

        // check tax
        (uint256 newUBI, uint256 newTreasury, ) = thespace.treasuryRecord();
        assertEq(newUBI + newTreasury, tax + prevUBI + prevTreasury);

        // check lastTaxCollection
        (, uint256 lastTaxCollection, ) = thespace.tokenRecord(PIXEL_ID);
        assertEq(lastTaxCollection, blockRollsTo);
    }

    /**
     * @dev UBI
     */
    function testGetUBIAvailable() public {
        // get UBI
        // roll block.number and check UBI
    }

    function testWithdrawUBI() public {
        // get UBI
        // withdrawa UBI
        // check UBI available
    }

    /**
     * @dev Trasfer
     */
    function testCannotTransferFrom() public {}

    function testCannotSafeTransferFrom() public {}
}
