//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./BaseTheSpace.t.sol";

contract TheSpaceTest is BaseTheSpaceTest {
    /**
     * Total Supply
     */
    function testTotalSupply() public {
        assertGt(registry.totalSupply(), 0);
    }

    function testSetTotalSupply(uint256 newTotalSupply) public {
        vm.assume(newTotalSupply > 0);

        // bid a token
        _bid(PIXEL_PRICE, PIXEL_PRICE);

        // collect tax
        _rollBlock();
        assertGt(thespace.getTax(PIXEL_ID), 0);
        thespace.settleTax(PIXEL_ID);

        // check prev UBI
        uint256 prevTotalSupply = registry.totalSupply();
        uint256 prevUBI = thespace.ubiAvailable(PIXEL_ID);
        assertGt(prevUBI, 0);

        // change total supply
        vm.prank(MARKET_ADMIN);
        thespace.setTotalSupply(newTotalSupply);

        // check new UBI
        uint256 newUBI = thespace.ubiAvailable(PIXEL_ID);
        if (newTotalSupply >= prevTotalSupply) {
            assertLe(newUBI, prevUBI);
        } else {
            assertGt(newUBI, prevUBI);
        }
    }

    function testCannotSetTotalSupplyByAttacker() public {
        vm.expectRevert(abi.encodeWithSignature("RoleRequired(uint8)", ROLE_MARKET_ADMIN));

        vm.prank(ATTACKER);
        thespace.setTotalSupply(1000);
    }

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

        vm.prank(ATTACKER);
        thespace.setTaxConfig(CONFIG_TAX_RATE, 1000);
    }

    function testSetTaxRate() public {
        // set tax rate
        uint256 taxRate = 1000;
        vm.prank(MARKET_ADMIN);
        vm.expectEmit(true, true, false, false);
        emit Config(CONFIG_TAX_RATE, taxRate);
        thespace.setTaxConfig(CONFIG_TAX_RATE, taxRate);

        // bid a token
        _bid();

        // roll block.number and check tax
        uint256 blockRollsTo = block.number + TAX_WINDOW;
        (, uint256 lastTaxCollection, ) = registry.tokenRecord(PIXEL_ID);
        uint256 tax = (PIXEL_PRICE * taxRate * (blockRollsTo - lastTaxCollection)) / (1000 * 10000);
        vm.roll(blockRollsTo);
        assertEq(thespace.getTax(PIXEL_ID), tax);
        assertGt(thespace.getTax(PIXEL_ID), 0);

        // change tax rate and recheck
        uint256 newTaxRate = 10;
        vm.prank(MARKET_ADMIN);
        vm.expectEmit(true, true, false, false);
        emit Config(CONFIG_TAX_RATE, newTaxRate);
        thespace.setTaxConfig(CONFIG_TAX_RATE, newTaxRate);
        uint256 newTax = (PIXEL_PRICE * newTaxRate * (blockRollsTo - lastTaxCollection)) / (1000 * 10000);
        vm.roll(blockRollsTo);
        assertEq(thespace.getTax(PIXEL_ID), newTax);
        assertGt(thespace.getTax(PIXEL_ID), 0);

        // zero tax
        vm.prank(MARKET_ADMIN);
        vm.expectEmit(true, true, false, false);
        emit Config(CONFIG_TAX_RATE, 0);
        thespace.setTaxConfig(CONFIG_TAX_RATE, 0);
        vm.roll(blockRollsTo);
        assertEq(thespace.getTax(PIXEL_ID), 0);
    }

    function testSetTreasuryShare() public {
        // set treasury share
        uint256 share = 1000;
        vm.prank(MARKET_ADMIN);
        vm.expectEmit(true, true, false, false);
        emit Config(CONFIG_TREASURY_SHARE, share);
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
        vm.expectEmit(true, true, false, false);
        emit Config(CONFIG_MINT_TAX, mintTax);
        _setMintTax(mintTax);

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
        vm.expectEmit(true, true, false, false);
        emit Treasury(TREASURY, amount);
        thespace.withdrawTreasury(TREASURY);

        // check treasury balance
        assertEq(currency.balanceOf(TREASURY), prevTreasuryBalance + amount);
        (, , uint256 newTreasuryWithdrawn) = registry.treasuryRecord();
        assertEq(newTreasuryWithdrawn, accumulatedTreasury);

        // check contract balance
        assertEq(currency.balanceOf(address(registry)), prevContractBalance - amount);
    }

    /**
     * @dev Pixel
     */
    function testGetNonExistingPixel() public {
        uint256 mintTax = 10 * (10**uint256(currency.decimals()));
        _setMintTax(mintTax);

        ITheSpaceRegistry.Pixel memory pixel = thespace.getPixel(PIXEL_ID);

        assertEq(pixel.price, mintTax);
        assertEq(pixel.color, 0);
        assertEq(pixel.owner, address(0));
    }

    function testGetExistingPixel() public {
        _bid(PIXEL_PRICE, PIXEL_PRICE);
        ITheSpaceRegistry.Pixel memory pixel = thespace.getPixel(PIXEL_ID);

        assertEq(pixel.price, PIXEL_PRICE);
        assertEq(pixel.color, 0);
        assertEq(pixel.owner, PIXEL_OWNER);
    }

    function testSetPixel(uint256 bidPrice) public {
        vm.assume(bidPrice > PIXEL_PRICE && bidPrice <= registry.currency().totalSupply());

        uint256 newPrice = bidPrice + 1;

        // bid with PIXEL_OWNER
        _bid();

        // bid with PIXEL_OWNER_1
        vm.expectEmit(true, true, true, true);
        emit Deal(PIXEL_ID, PIXEL_OWNER, PIXEL_OWNER_1, thespace.getPrice(PIXEL_ID));

        // set to bid price from `bid()`
        vm.expectEmit(true, true, true, false);
        emit Price(PIXEL_ID, bidPrice, PIXEL_OWNER_1);

        // set to new price from `setPrice()`
        vm.expectEmit(true, true, true, false);
        emit Price(PIXEL_ID, newPrice, PIXEL_OWNER_1);

        vm.expectEmit(true, true, true, false);
        emit Color(PIXEL_ID, PIXEL_COLOR, PIXEL_OWNER_1);

        vm.prank(PIXEL_OWNER_1);
        thespace.setPixel(PIXEL_ID, bidPrice, newPrice, PIXEL_COLOR);

        assertEq(thespace.getPrice(PIXEL_ID), newPrice);
        assertEq(thespace.getColor(PIXEL_ID), PIXEL_COLOR);
    }

    function testCannotSetPixel(uint256 bidPrice) public {
        vm.assume(bidPrice < PIXEL_PRICE);

        // bid with PIXEL_OWNER
        _bid();

        // PIXEL_OWNER_1 bids with lower price
        vm.prank(PIXEL_OWNER_1);
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("PriceTooLow()"))));
        thespace.setPixel(PIXEL_ID, bidPrice, bidPrice, PIXEL_COLOR);
    }

    function testBatchSetPixels(uint16 price, uint8 color) public {
        uint256 finalPrice = uint256(price) + 1;
        uint256 finalColor = 5;

        bytes[] memory data = new bytes[](3);

        // bid pixel
        data[0] = abi.encodeWithSignature(
            "setPixel(uint256,uint256,uint256,uint256)",
            PIXEL_ID,
            PIXEL_PRICE,
            uint256(price),
            uint256(color)
        );

        // set price
        data[1] = abi.encodeWithSignature(
            "setPixel(uint256,uint256,uint256,uint256)",
            PIXEL_ID,
            PIXEL_PRICE,
            finalPrice,
            uint256(color)
        );

        // set color
        data[2] = abi.encodeWithSignature(
            "setPixel(uint256,uint256,uint256,uint256)",
            PIXEL_ID,
            PIXEL_PRICE,
            finalPrice,
            finalColor
        );

        vm.prank(PIXEL_OWNER);
        thespace.multicall(data);

        assertEq(thespace.getPrice(PIXEL_ID), finalPrice);
        assertEq(thespace.getColor(PIXEL_ID), finalColor);
    }

    /**
     * @dev Color
     */
    function testSetColor() public {
        _bid();

        uint256 color = 5;
        vm.prank(PIXEL_OWNER);
        vm.expectEmit(true, true, true, false);
        emit Color(PIXEL_ID, color, PIXEL_OWNER);
        thespace.setColor(PIXEL_ID, color);

        assertEq(thespace.getColor(PIXEL_ID), color);
    }

    function testCannotSetColorByAttacker() public {
        _bid();

        uint256 color = 6;

        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("Unauthorized()"))));
        thespace.setColor(PIXEL_ID, color);
    }

    /**
     * @dev Owner Tokens
     */
    function _assertEqArray(ITheSpaceRegistry.Pixel[] memory a, ITheSpaceRegistry.Pixel[] memory b) private {
        assert(a.length == b.length);
        for (uint256 i = 0; i < a.length; i++) {
            assertEq(a[i].tokenId, b[i].tokenId);
            assertEq(a[i].price, b[i].price);
            assertEq(a[i].lastTaxCollection, b[i].lastTaxCollection);
            assertEq(a[i].ubi, b[i].ubi);
            assertEq(a[i].owner, b[i].owner);
            assertEq(a[i].color, b[i].color);
        }
    }

    function testGetPixelsByOwnerWithNoPixels() public {
        ITheSpaceRegistry.Pixel[] memory empty = new ITheSpaceRegistry.Pixel[](0);

        assertEq(registry.balanceOf(PIXEL_OWNER), 0);
        (uint256 total0, uint256 limit0, uint256 offset0, ITheSpaceRegistry.Pixel[] memory pixels0) = thespace
            .getPixelsByOwner(PIXEL_OWNER, 1, 0);
        assertEq(total0, 0);
        assertEq(limit0, 1);
        assertEq(offset0, 0);
        _assertEqArray(pixels0, empty);
        (, , , ITheSpaceRegistry.Pixel[] memory pixels1) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 1);
        _assertEqArray(pixels1, empty);
        (, , , ITheSpaceRegistry.Pixel[] memory pixels2) = thespace.getPixelsByOwner(PIXEL_OWNER, 0, 0);
        _assertEqArray(pixels2, empty);
    }

    function testGetPixelsByOwnerWithOnePixel() public {
        uint256 tokenId1 = 100;
        ITheSpaceRegistry.Pixel[] memory empty = new ITheSpaceRegistry.Pixel[](0);
        ITheSpaceRegistry.Pixel[] memory one = new ITheSpaceRegistry.Pixel[](1);
        _bidThis(tokenId1, PIXEL_PRICE);
        one[0] = thespace.getPixel(tokenId1);

        assertEq(registry.balanceOf(PIXEL_OWNER), 1);
        // get this pixel
        (uint256 total0, uint256 limit0, uint256 offset0, ITheSpaceRegistry.Pixel[] memory pixels0) = thespace
            .getPixelsByOwner(PIXEL_OWNER, 1, 0);
        assertEq(total0, 1);
        assertEq(limit0, 1);
        assertEq(offset0, 0);
        _assertEqArray(pixels0, one);
        (, , , ITheSpaceRegistry.Pixel[] memory pixels1) = thespace.getPixelsByOwner(PIXEL_OWNER, 10, 0);
        _assertEqArray(pixels1, one);
        // query with limit=0
        (uint256 total2, uint256 limit2, , ITheSpaceRegistry.Pixel[] memory pixels2) = thespace.getPixelsByOwner(
            PIXEL_OWNER,
            0,
            0
        );
        assertEq(total2, 1);
        assertEq(limit2, 0);
        _assertEqArray(pixels2, empty);
        (, , , ITheSpaceRegistry.Pixel[] memory pixels3) = thespace.getPixelsByOwner(PIXEL_OWNER, 0, 1);
        _assertEqArray(pixels3, empty);
        // query with offset>=total
        (, , , ITheSpaceRegistry.Pixel[] memory pixels4) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 1);
        _assertEqArray(pixels4, empty);
        (, , , ITheSpaceRegistry.Pixel[] memory pixels5) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 2);
        _assertEqArray(pixels5, empty);
    }

    function testGetPixelsPageByOwnerWithPixels() public {
        uint256 tokenId1 = 100;
        uint256 tokenId2 = 101;
        ITheSpaceRegistry.Pixel[] memory empty = new ITheSpaceRegistry.Pixel[](0);
        ITheSpaceRegistry.Pixel[] memory two = new ITheSpaceRegistry.Pixel[](2);

        _bidThis(tokenId1, PIXEL_PRICE);
        _bidThis(tokenId2, PIXEL_PRICE);
        two[0] = thespace.getPixel(tokenId1);
        two[1] = thespace.getPixel(tokenId2);

        // query with limit>=total
        assertEq(registry.balanceOf(PIXEL_OWNER), 2);
        (uint256 total0, uint256 limit0, uint256 offset0, ITheSpaceRegistry.Pixel[] memory pixels0) = thespace
            .getPixelsByOwner(PIXEL_OWNER, 2, 0);
        assertEq(total0, 2);
        assertEq(limit0, 2);
        assertEq(offset0, 0);
        _assertEqArray(pixels0, two);
        (, , , ITheSpaceRegistry.Pixel[] memory pixels1) = thespace.getPixelsByOwner(PIXEL_OWNER, 10, 0);
        _assertEqArray(pixels1, two);

        // query with 0<limit<total
        ITheSpaceRegistry.Pixel[] memory pixelsPage1 = new ITheSpaceRegistry.Pixel[](1);
        ITheSpaceRegistry.Pixel[] memory pixelsPage2 = new ITheSpaceRegistry.Pixel[](1);
        pixelsPage1[0] = thespace.getPixel(tokenId1);
        pixelsPage2[0] = thespace.getPixel(tokenId2);
        (uint256 total2, , , ITheSpaceRegistry.Pixel[] memory pixels2) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 0);
        assertEq(total2, 2);
        _assertEqArray(pixels2, pixelsPage1);
        (, , , ITheSpaceRegistry.Pixel[] memory pixels3) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 1);
        _assertEqArray(pixels3, pixelsPage2);
        // query with offset>=total
        (, , , ITheSpaceRegistry.Pixel[] memory pixels4) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 2);
        _assertEqArray(pixels4, empty);
        (, , , ITheSpaceRegistry.Pixel[] memory pixels5) = thespace.getPixelsByOwner(PIXEL_OWNER, 1, 10);
        _assertEqArray(pixels5, empty);
    }

    /**
     * @dev Price
     */
    function testGetPrice() public {
        _bid();
        assertEq(thespace.getPrice(PIXEL_ID), PIXEL_PRICE);
    }

    function testGetNonExistingPrice() public {
        uint256 mintTax = registry.taxConfig(CONFIG_MINT_TAX);
        assertEq(thespace.getPrice(PIXEL_ID + 1), mintTax);
    }

    function testSetPrice(uint256 price) public {
        vm.assume(price <= registry.currency().totalSupply());

        // bid a token and set price
        _bid(PIXEL_PRICE, price);
        assertEq(thespace.getPrice(PIXEL_ID), price);
    }

    function testSetPriceByOperator(uint256 price) public {
        vm.assume(price <= registry.currency().totalSupply());

        // bid a token and set price
        _bid();

        // approve pixel to operator
        vm.prank(PIXEL_OWNER);
        registry.approve(OPERATOR, PIXEL_ID);

        // set price
        vm.expectEmit(true, true, true, false);
        emit Price(PIXEL_ID, price, PIXEL_OWNER);
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

        uint256 maxPrice = registry.currency().totalSupply();
        uint256 newPrice = maxPrice + 1;

        vm.expectRevert(abi.encodeWithSignature("PriceTooHigh(uint256)", maxPrice));
        vm.prank(PIXEL_OWNER);
        thespace.setPrice(PIXEL_ID, newPrice);
    }

    /**
     * @dev Owner
     */
    function testGetOwner() public {
        _bid();
        assertEq(thespace.getOwner(PIXEL_ID), PIXEL_OWNER);

        _bidAs(PIXEL_OWNER_1, thespace.getPrice(PIXEL_ID));
        assertEq(thespace.getOwner(PIXEL_ID), PIXEL_OWNER_1);
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

        uint256 bidderCurrencyOldBlanace = currency.balanceOf(PIXEL_OWNER_1);
        uint256 sellerCurrencyOldBlanace = currency.balanceOf(PIXEL_OWNER);
        // PIXEL_OWNER_1 bids a pixel from PIXEL_OWNER
        uint256 newBidPrice = PIXEL_PRICE + 1000;
        _bidAs(PIXEL_OWNER_1, newBidPrice);

        // check balance
        assertEq(registry.balanceOf(PIXEL_OWNER), 0);
        assertEq(registry.balanceOf(PIXEL_OWNER_1), 1);

        // check currency balance
        assertEq(currency.balanceOf(PIXEL_OWNER_1), bidderCurrencyOldBlanace - PIXEL_PRICE);
        assertEq(currency.balanceOf(PIXEL_OWNER), sellerCurrencyOldBlanace + PIXEL_PRICE);

        // check ownership
        assertEq(thespace.getOwner(PIXEL_ID), PIXEL_OWNER_1);

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
        uint256 price = registry.currency().totalSupply();
        _bid(PIXEL_PRICE, price);

        // check tax is greater than balance
        _rollBlock();
        uint256 tax = thespace.getTax(PIXEL_ID);
        assertLt(currency.balanceOf(PIXEL_OWNER_1), tax);

        // set mint tax
        uint256 mintTax = 50 * (10**uint256(currency.decimals()));
        _setMintTax(mintTax);

        // bid and token will be defaulted
        uint256 prevBalance = currency.balanceOf(PIXEL_OWNER_1);
        _bidAs(PIXEL_OWNER_1, PIXEL_PRICE);

        // bidder only pays the mint tax
        assertEq(currency.balanceOf(PIXEL_OWNER_1), prevBalance - mintTax);

        // tax paid by the old owner
        assertEq(currency.balanceOf(PIXEL_OWNER), 0);

        // tax was clear
        assertEq(thespace.getTax(PIXEL_ID), 0);

        // ownership was transferred
        assertEq(thespace.getOwner(PIXEL_ID), PIXEL_OWNER_1);

        // price didn't change since bid price is lower than the old price
        assertEq(thespace.getPrice(PIXEL_ID), price);
    }

    function testCannotBidOutBoundTokens() public {
        vm.startPrank(PIXEL_OWNER_1);

        uint256 totalSupply = registry.totalSupply();

        // oversupply id
        vm.expectRevert(abi.encodeWithSignature("InvalidTokenId(uint256,uint256)", 1, totalSupply));
        thespace.bid(totalSupply + 1, PIXEL_PRICE);

        // zero id
        vm.expectRevert(abi.encodeWithSignature("InvalidTokenId(uint256,uint256)", 1, totalSupply));
        thespace.bid(0, PIXEL_PRICE);

        vm.stopPrank();
    }

    function testCannotBidPriceTooLow() public {
        // bid and set price
        _bid(PIXEL_PRICE, PIXEL_PRICE);

        // price too low to bid a existing token
        vm.expectRevert(abi.encodeWithSignature("PriceTooLow()"));
        _bidAs(PIXEL_OWNER_1, PIXEL_PRICE - 1);

        // price too low to bid a non-existing token
        uint256 mintTax = 50 * (10**uint256(currency.decimals()));
        _setMintTax(mintTax);

        vm.expectRevert(abi.encodeWithSignature("PriceTooLow()"));
        _bidAs(PIXEL_OWNER_1, mintTax - 1);
    }

    function testCannotBidExceedAllowance() public {
        // set mint tax
        uint256 mintTax = 50 * (10**uint256(currency.decimals()));
        _setMintTax(mintTax);

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

        vm.prank(PIXEL_OWNER);
        currency.approve(address(registry), 0);
        thespace.settleTax(PIXEL_ID);

        // token was burned
        assertEq(registry.balanceOf(PIXEL_OWNER), 0);

        // price was reset
        uint256 mintTax = 50 * (10**uint256(currency.decimals()));
        _setMintTax(mintTax);
        assertEq(thespace.getPrice(PIXEL_ID), mintTax);

        // bid with mint tax
        vm.expectEmit(true, true, true, false);
        emit Tax(PIXEL_ID, PIXEL_OWNER_1, mintTax);
        uint256 prevBalance = currency.balanceOf(PIXEL_OWNER_1);
        _bidAs(PIXEL_OWNER_1, mintTax);
        assertEq(currency.balanceOf(PIXEL_OWNER_1), prevBalance - mintTax);
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
        vm.expectEmit(true, true, true, false);
        emit UBI(PIXEL_ID, PIXEL_OWNER_1, ubi);
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
        vm.stopPrank();

        // ownership was transferred to zero address
        assertEq(thespace.getOwner(PIXEL_ID), address(0));

        // price was reset to mint tax since it was burned
        uint256 mintTax = 50 * (10**uint256(currency.decimals()));
        _setMintTax(mintTax);
        assertEq(thespace.getPrice(PIXEL_ID), mintTax);

        // tax was clear
        _bidAs(PIXEL_OWNER_1, mintTax);
        assertEq(thespace.getTax(PIXEL_ID), 0);
    }

    function testCanTransferFromIfSettleTax() public {
        // bid and set price
        _bid(PIXEL_PRICE, PIXEL_PRICE);

        _rollBlock();

        vm.startPrank(PIXEL_OWNER);
        registry.transferFrom(PIXEL_OWNER, PIXEL_OWNER_1, PIXEL_ID);
        vm.stopPrank();

        assertEq(thespace.getOwner(PIXEL_ID), PIXEL_OWNER_1);

        // tax was clear
        assertEq(thespace.getTax(PIXEL_ID), 0);

        // price was reset to zero
        uint256 mintTax = 50 * (10**uint256(currency.decimals()));
        _setMintTax(mintTax);
        assertEq(thespace.getPrice(PIXEL_ID), 0);
    }
}
