//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import {DSTest} from "ds-test/test.sol";
import {console} from "./utils/Console.sol";
import {Hevm} from "./utils/Hevm.sol";
import {Logbook} from "../Logbook/Logbook.sol";

contract LogbookTest is DSTest {
    Logbook private logbook;

    Hevm constant vm = Hevm(HEVM_ADDRESS);

    address constant DEPLOYER = address(176);
    address constant TRAVELOGGERS_OWNER = address(177);
    address constant PUBLIC_SALE_MINTER = address(178);
    address constant ATTACKER = address(179);
    address constant APPROVED = address(180);
    address constant FRONTEND_OPERATOR = address(181);

    uint128 constant _ROYALTY_BPS_LOGBOOK_OWNER = 8000;
    uint128 constant _PUBLIC_SALE_ON = 1;
    uint128 constant _PUBLIC_SALE_OFF = 2;

    uint256 constant CLAIM_TOKEN_START_ID = 1;
    uint256 constant CLAIM_TOKEN_END_ID = 1500;

    event SetTitle(uint256 indexed tokenId, string title);

    event SetDescription(uint256 indexed tokenId, string description);

    event SetForkPrice(uint256 indexed tokenId, uint256 amount);

    event Publish(uint256 indexed tokenId, address indexed author, bytes32 indexed contentHash, string content);

    event Fork(
        uint256 indexed tokenId,
        uint256 indexed newTokenId,
        address indexed owner,
        bytes32 contentHash,
        uint256 amount
    );

    event Donate(uint256 indexed tokenId, address indexed donor, uint256 amount);

    function setUp() public {
        vm.prank(DEPLOYER);
        logbook = new Logbook("Logbook", "LBK");
    }

    /**
     * Claim
     */
    function _claimToTraveloggersOwner() private {
        vm.prank(DEPLOYER);
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_START_ID);
        assertEq(logbook.ownerOf(CLAIM_TOKEN_START_ID), TRAVELOGGERS_OWNER);
        assertEq(logbook.balanceOf(TRAVELOGGERS_OWNER), 1);
    }

    function testClaim() public {
        // only owner
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("Ownable: caller is not the owner");
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_END_ID);

        // token has not been claimed yet
        vm.expectRevert("ERC721: owner query for nonexistent token");
        logbook.ownerOf(CLAIM_TOKEN_START_ID);

        assertEq(logbook.balanceOf(TRAVELOGGERS_OWNER), 0);

        // claim
        _claimToTraveloggersOwner();

        // token can't be claimed again
        vm.prank(DEPLOYER);
        vm.expectRevert("ERC721: token already minted");
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_START_ID);

        // invalid token id
        vm.prank(DEPLOYER);
        vm.expectRevert("invalid logrs id");
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_START_ID - 1);

        vm.prank(DEPLOYER);
        vm.expectRevert("invalid logrs id");
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_END_ID + 1);
    }

    /**
     * Public Sale
     */
    function testPublicSale() public {
        uint256 price = 1 ether;

        // not started
        vm.expectRevert("not started");
        logbook.publicSaleMint();

        // turn on: set state (1/2)
        vm.prank(DEPLOYER);
        logbook.togglePublicSale();
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("not started");
        logbook.publicSaleMint();

        // turn on: set price (2/2)
        vm.prank(DEPLOYER);
        logbook.setPublicSalePrice(price);
        assertEq(logbook.publicSalePrice(), price);

        // zero value
        vm.prank(DEPLOYER);
        vm.expectRevert("zero value");
        logbook.setPublicSalePrice(0);

        // mint
        uint256 deployerBalanceBefore = DEPLOYER.balance;
        vm.deal(PUBLIC_SALE_MINTER, price + 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        uint256 tokenId = logbook.publicSaleMint{value: price}();
        assertEq(tokenId, CLAIM_TOKEN_END_ID + 1);
        assertEq(logbook.ownerOf(tokenId), PUBLIC_SALE_MINTER);

        // deployer receives ether
        assertEq(DEPLOYER.balance, deployerBalanceBefore + price);

        // not engough ether to mint
        vm.expectRevert("value too small");
        vm.deal(PUBLIC_SALE_MINTER, price + 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        logbook.publicSaleMint{value: price - 0.01 ether}();
    }

    /**
     * Title, Description, Fork Price, Publish...
     */
    function _setForkPrice(uint256 forkPrice) private {
        vm.prank(TRAVELOGGERS_OWNER);
        vm.expectEmit(true, true, false, false);
        emit SetForkPrice(CLAIM_TOKEN_START_ID, forkPrice);
        logbook.setForkPrice(CLAIM_TOKEN_START_ID, forkPrice);
        (uint256 returnForkPrice, , ) = logbook.getLogbook(CLAIM_TOKEN_START_ID);
        assertEq(returnForkPrice, forkPrice);
    }

    function _publish(string memory content) private returns (bytes32 contentHash) {
        contentHash = keccak256(abi.encodePacked(content));

        vm.prank(TRAVELOGGERS_OWNER);
        vm.expectEmit(true, true, true, true);
        emit Publish(CLAIM_TOKEN_START_ID, TRAVELOGGERS_OWNER, contentHash, content);
        logbook.publish(CLAIM_TOKEN_START_ID, content);
    }

    function testSetTitle() public {
        _claimToTraveloggersOwner();
        string memory title = "Sit deserunt nulla aliqua ex nisi";

        // set title
        vm.prank(TRAVELOGGERS_OWNER);
        vm.expectEmit(true, true, false, false);
        emit SetTitle(CLAIM_TOKEN_START_ID, title);
        logbook.setTitle(CLAIM_TOKEN_START_ID, title);

        // only logbook owner
        vm.prank(ATTACKER);
        vm.expectRevert("caller is not owner nor approved");
        logbook.setTitle(CLAIM_TOKEN_START_ID, title);

        // approve other address
        vm.startPrank(TRAVELOGGERS_OWNER);
        logbook.approve(APPROVED, CLAIM_TOKEN_START_ID);
        logbook.getApproved(CLAIM_TOKEN_START_ID);
        vm.stopPrank();

        vm.prank(APPROVED);
        logbook.setTitle(CLAIM_TOKEN_START_ID, title);
    }

    function testSetDescription() public {
        _claimToTraveloggersOwner();
        string
            memory description = "Quis commodo sunt ea est aliquip enim aliquip ullamco eu. Excepteur aliquip enim irure dolore deserunt fugiat consectetur esse in deserunt commodo in eiusmod esse. Cillum cupidatat dolor voluptate in id consequat nulla aliquip. Deserunt sunt aute eu aliqua consequat nulla aliquip excepteur exercitation. Lorem ex magna deserunt duis dolor dolore mollit.";

        // set description
        vm.prank(TRAVELOGGERS_OWNER);
        vm.expectEmit(true, true, false, false);
        emit SetDescription(CLAIM_TOKEN_START_ID, description);
        logbook.setDescription(CLAIM_TOKEN_START_ID, description);

        // only logbook owner
        vm.prank(ATTACKER);
        vm.expectRevert("caller is not owner nor approved");
        logbook.setTitle(CLAIM_TOKEN_START_ID, description);
    }

    function testSetForkPrice() public {
        _claimToTraveloggersOwner();

        // set fork price
        uint256 forkPrice = 0.1 ether;
        _setForkPrice(forkPrice);

        // only logbook owner
        vm.prank(ATTACKER);
        vm.expectRevert("caller is not owner nor approved");
        logbook.setForkPrice(CLAIM_TOKEN_START_ID, forkPrice);
    }

    function testPublish(string calldata content) public {
        _claimToTraveloggersOwner();
        bytes32 contentHash = keccak256(abi.encodePacked(content));

        // publish
        bytes32 returnContentHash = _publish(content);
        assertEq(contentHash, returnContentHash);
        (, bytes32[] memory contentHashes, ) = logbook.getLogbook(CLAIM_TOKEN_START_ID);
        assertEq(contentHashes.length, 1);

        // only logbook owner
        vm.prank(ATTACKER);
        vm.expectRevert("caller is not owner nor approved");
        logbook.publish(CLAIM_TOKEN_START_ID, content);
    }

    // function testMulticall() public {}

    /**
     * Donate, Fork, Withdraw...
     */
    function testDonate(uint256 amount) public {
        _claimToTraveloggersOwner();

        // donate
        vm.deal(PUBLIC_SALE_MINTER, amount);
        vm.prank(PUBLIC_SALE_MINTER);
        if (amount > 0) {
            vm.expectEmit(true, true, true, false);
            emit Donate(CLAIM_TOKEN_START_ID, PUBLIC_SALE_MINTER, amount);
            logbook.donate{value: amount}(CLAIM_TOKEN_START_ID);
        } else {
            vm.expectRevert("zero value");
            logbook.donate{value: amount}(CLAIM_TOKEN_START_ID);
        }

        // no logbook
        vm.deal(PUBLIC_SALE_MINTER, 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("ERC721: operator query for nonexistent token");
        logbook.donate{value: 1 ether}(CLAIM_TOKEN_START_ID + 1);
    }

    function testDonateWithCommission(uint256 amount, uint128 bps) public {
        _claimToTraveloggersOwner();

        bool isInvalidBPS = bps > 10000 - _ROYALTY_BPS_LOGBOOK_OWNER;

        // donate
        vm.deal(PUBLIC_SALE_MINTER, amount);
        vm.prank(PUBLIC_SALE_MINTER);
        if (amount > 0) {
            if (isInvalidBPS) {
                vm.expectRevert("invalid BPS");
            } else {
                vm.expectEmit(true, true, true, false);
                emit Donate(CLAIM_TOKEN_START_ID, PUBLIC_SALE_MINTER, amount);
            }
            logbook.donateWithCommission{value: amount}(CLAIM_TOKEN_START_ID, FRONTEND_OPERATOR, bps);
        } else {
            vm.expectRevert("zero value");
            logbook.donateWithCommission{value: amount}(CLAIM_TOKEN_START_ID, FRONTEND_OPERATOR, bps);
        }

        // no logbook
        vm.deal(PUBLIC_SALE_MINTER, 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("ERC721: operator query for nonexistent token");
        logbook.donate{value: 1 ether}(CLAIM_TOKEN_START_ID + 1);
    }

    function testFork(uint256 amount) public {
        _claimToTraveloggersOwner();

        string memory content = "Magna fugiat enim ullamco minim ea aliquip incididunt amet.";
        bytes32 contentHash = keccak256(abi.encodePacked(content));

        // no logbook
        vm.deal(PUBLIC_SALE_MINTER, 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("ERC721: operator query for nonexistent token");
        logbook.fork{value: 1 ether}(CLAIM_TOKEN_START_ID + 1, contentHash);

        // no content
        vm.deal(PUBLIC_SALE_MINTER, 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("no content");
        logbook.fork{value: 1 ether}(CLAIM_TOKEN_START_ID, contentHash);

        _publish(content);

        // value too small
        uint256 forkPrice = 0.1 ether;
        _setForkPrice(forkPrice);
        vm.deal(PUBLIC_SALE_MINTER, forkPrice);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("value too small");
        logbook.fork{value: forkPrice / 2}(CLAIM_TOKEN_START_ID, contentHash);

        // fork
        if (amount <= type(uint256).max / 10000) {
            _setForkPrice(amount);
            vm.deal(PUBLIC_SALE_MINTER, amount);
            vm.prank(PUBLIC_SALE_MINTER);
            vm.expectEmit(true, true, true, true);
            emit Fork(CLAIM_TOKEN_START_ID, CLAIM_TOKEN_END_ID + 1, PUBLIC_SALE_MINTER, contentHash, amount);
            logbook.fork{value: amount}(CLAIM_TOKEN_START_ID, contentHash);
        }
    }

    // royalties
}
