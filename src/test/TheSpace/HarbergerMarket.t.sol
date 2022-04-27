//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./BaseTheSpace.t.sol";

contract TheSpaceTest is BaseTheSpaceTest {
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
    function testGetConfig() public {}

    function testCannotSetConfigByAttacker() public {}

    function testSetTaxRate() public {
        // set tax rate
        // bid a pixel
        // roll the block.number and check tax
    }

    function testSetTreasuryShare() public {
        // set treasury share
        // bid a pixel
        // roll the block.number, collect tax, and check treasury
    }

    function testSetMintTax() public {
        // set mint tax
        // bid a pixel
    }

    function testWithdrawTreasury() public {}

    /**
     * @dev Price
     */
    function testGetPrice() public {}

    function testSetPrice() public {
        _price();
        assertEq(thespace.getPrice(PIXEL_ID), PIXEL_PRICE);
    }

    function testCannotGetPriceByNonOwner() public {}

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
        vm.roll(block.number + TAX_WINDOW);

        currency.approve(address(thespace), 0);

        (, bool shouldDefault) = thespace.evaluateOwnership(PIXEL_ID);

        assertTrue(shouldDefault);
    }

    function testDefault() public {
        _price();

        vm.roll(block.number + TAX_WINDOW);

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
        vm.roll(block.number + TAX_WINDOW);

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
