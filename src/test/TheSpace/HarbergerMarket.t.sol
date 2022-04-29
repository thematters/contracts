//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./BaseHarbergerMarket.t.sol";

contract HarbergerMarketTest is BaseHarbergerMarket {
    /**
     * Total Supply
     */
    function testTotalSupply() public {
        assertEq(thespace.totalSupply(), TOTAL_SUPPLY);
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
        vm.stopPrank();

        // set tax rate
        uint256 taxRate = 1000;
        vm.prank(MARKET_ADMIN);
        thespace.setTaxConfig(CONFIG_TAX_RATE, taxRate);

        // bid a pixel
        vm.prank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, PIXEL_PRICE);

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
        vm.stopPrank();

        // set treasury share
        uint256 share = 1000;
        vm.prank(MARKET_ADMIN);
        thespace.setTaxConfig(CONFIG_TREASURY_SHARE, share);

        // bid a pixel
        vm.prank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, PIXEL_PRICE);

        // check treasury share
        _rollBlock();
        uint256 tax = thespace.getTax(PIXEL_ID);
        (, uint256 prevTreasury, ) = thespace.treasuryRecord();
        uint256 expectTreasury = prevTreasury + ((tax * share) / 10000);
        assertGt(prevTreasury, 0);

        thespace.settleTax(PIXEL_ID);

        (, uint256 newTreasury, ) = thespace.treasuryRecord();
        assertEq(newTreasury, expectTreasury);
        assertGt(newTreasury, 0);
    }

    function testSetMintTax() public {
        vm.stopPrank();

        // set mint tax
        uint256 mintTax = 50 * (10**uint256(currency.decimals()));
        vm.prank(MARKET_ADMIN);
        thespace.setTaxConfig(CONFIG_MINT_TAX, mintTax);

        // bid a pixel with mint tax as amount
        uint256 prevBalance = currency.balanceOf(PIXEL_OWNER);
        vm.prank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, mintTax);
        assertEq(currency.balanceOf(PIXEL_OWNER), prevBalance - mintTax);
    }

    function testWithdrawTreasury() public {
        vm.stopPrank();

        // bid a pixel
        vm.prank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, PIXEL_PRICE);

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
        vm.stopPrank();

        // bid a pixel
        vm.prank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, PIXEL_PRICE);

        assertEq(thespace.getPrice(PIXEL_ID), PIXEL_PRICE);
    }

    function testGetNonExistingPixelPrice() public {
        assertEq(thespace.getPrice(PIXEL_ID + 1), MINT_TAX);
    }

    function testSetPixelPrice() public {
        vm.stopPrank();

        uint256 price = 1000;

        // bid a pixel and set price
        vm.startPrank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, PIXEL_PRICE);
        thespace.setPrice(PIXEL_ID, price);
        vm.stopPrank();

        assertEq(thespace.getPrice(PIXEL_ID), price);
    }

    function testSetPixelPriceByOperator() public {
        vm.stopPrank();

        uint256 price = 99;

        // bid a pixel and set price
        vm.prank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, PIXEL_PRICE);

        // approve pixel to operator
        vm.prank(PIXEL_OWNER);
        thespace.approve(OPERATOR, PIXEL_ID);

        // set price
        vm.prank(OPERATOR);
        thespace.setPrice(PIXEL_ID, price);
        assertEq(thespace.getPrice(PIXEL_ID), price);
    }

    function testCannotSetPriceByNonOwner() public {
        vm.stopPrank();

        // bid a pixel and set price
        vm.prank(PIXEL_OWNER);
        thespace.bid(PIXEL_ID, PIXEL_PRICE);

        // someone tries to set price
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        vm.prank(ATTACKER);
        thespace.setPrice(PIXEL_ID, PIXEL_PRICE);
    }

    /**
     * @dev Owner
     */
    function testGetOwner() public {
        // token that exists
        // token that non-exists
    }

    /**
     * @dev Bid
     */
    function testBid() public {
        _bid();
        assertEq(thespace.balanceOf(PIXEL_OWNER), 1);
    }

    function testCannotBidByNonOwner() public {}

    function testBidNewToken() public {
        // bid
        // check ownership
        // check price
        // check tax & lastTaxCollection
    }

    function testBidDefaultedToken() public {}

    function testCannotBidOversupplyToken() public {}

    /**
     * @dev Ownership
     */
    function testEvaluateOwnership() public {
        // should be defaulted if no tax can be collected
        _price();
        _rollBlock();

        currency.approve(address(thespace), 0);

        (, bool shouldDefault) = thespace.evaluateOwnership(PIXEL_ID);

        assertTrue(shouldDefault);
    }

    function testDefault() public {
        _price();
        _rollBlock();

        currency.approve(address(thespace), 0);
        thespace.settleTax(PIXEL_ID);

        assertEq(thespace.balanceOf(PIXEL_OWNER), 0);
    }

    /**
     * @dev Tax
     */
    function testGetTax() public {}

    function testSettleTax() public {
        _price();
        _rollBlock();

        vm.expectEmit(true, true, false, false);
        emit Tax(PIXEL_ID, PIXEL_OWNER, 10);

        thespace.settleTax(PIXEL_ID);

        (uint256 accumulatedUBI, , ) = thespace.treasuryRecord();
        assertGt(accumulatedUBI, 0);
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
