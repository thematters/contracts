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

    uint256 constant _ROYALTY_BPS_LOGBOOK_OWNER = 8000;
    uint256 constant _PUBLIC_SALE_ON = 1;
    uint256 constant _PUBLIC_SALE_OFF = 2;

    uint256 constant CLAIM_TOKEN_START_ID = 1;
    uint256 constant CLAIM_TOKEN_END_ID = 1500;

    event SetTitle(uint256 indexed tokenId, string title);

    event SetDescription(uint256 indexed tokenId, string description);

    event SetForkPrice(uint256 indexed tokenId, uint256 amount);

    event Content(address indexed author, bytes32 indexed contentHash, string content);

    event Publish(uint256 indexed tokenId, bytes32 indexed contentHash);

    event Fork(uint256 indexed tokenId, uint256 indexed newTokenId, address indexed owner, uint256 end, uint256 amount);

    event Donate(uint256 indexed tokenId, address indexed donor, uint256 amount);

    enum RoyaltyPurpose {
        Fork,
        Donate
    }
    event Pay(
        uint256 indexed tokenId,
        address indexed sender,
        address indexed recipient,
        RoyaltyPurpose purpose,
        uint256 amount
    );

    event Withdraw(address indexed account, uint256 amount);

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
        uint256 deployerWalletBalance = DEPLOYER.balance;
        vm.deal(PUBLIC_SALE_MINTER, price + 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        uint256 tokenId = logbook.publicSaleMint{value: price}();
        assertEq(tokenId, CLAIM_TOKEN_END_ID + 1);
        assertEq(logbook.ownerOf(tokenId), PUBLIC_SALE_MINTER);

        // deployer receives ether
        assertEq(DEPLOYER.balance, deployerWalletBalance + price);

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
        vm.expectEmit(true, true, true, false);
        emit Content(TRAVELOGGERS_OWNER, contentHash, content);
        vm.expectEmit(true, true, false, false);
        emit Publish(CLAIM_TOKEN_START_ID, contentHash);
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

    /**
     * Set title, description, fork price and publish new content
     * in one transaction
     */
    function testMulticall() public {
        _claimToTraveloggersOwner();

        bytes[] memory data = new bytes[](4);

        // title
        string memory title = "Sit deserunt nulla aliqua ex nisi";
        data[0] = abi.encodeWithSignature("setTitle(uint256,string)", CLAIM_TOKEN_START_ID, title);

        // description
        string
            memory description = "Deserunt proident dolor id Lorem pariatur irure adipisicing labore labore aute sunt aliquip culpa consectetur laboris.";
        data[1] = abi.encodeWithSignature("setDescription(uint256,string)", CLAIM_TOKEN_START_ID, description);

        // fork price
        uint256 forkPrice = 0.122 ether;
        data[2] = abi.encodeWithSignature("setForkPrice(uint256,uint256)", CLAIM_TOKEN_START_ID, forkPrice);

        // publish
        string
            memory content = "Fugiat proident irure et mollit quis occaecat labore cupidatat ut aute tempor esse exercitation eiusmod. Do commodo incididunt quis exercitation laboris adipisicing nisi. Magna aliquip aute mollit id aliquip incididunt sint ea laborum mollit eiusmod do aliquip aute. Enim ea eiusmod pariatur mollit pariatur irure consectetur anim. Proident elit nisi ea laboris ad reprehenderit. Consectetur consequat excepteur duis tempor nulla id in commodo occaecat. Excepteur quis nostrud velit exercitation ut ullamco tempor nulla non. Occaecat laboris anim labore ut adipisicing nisi. Sit enim dolor eiusmod ipsum nulla quis aliqua reprehenderit ea. Lorem sit tempor consequat magna Lorem deserunt duis.";
        data[3] = abi.encodeWithSignature("publish(uint256,string)", CLAIM_TOKEN_START_ID, content);

        // call
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        vm.prank(TRAVELOGGERS_OWNER);
        vm.expectEmit(true, true, false, false);
        emit SetTitle(CLAIM_TOKEN_START_ID, title);
        vm.expectEmit(true, true, false, false);
        emit SetDescription(CLAIM_TOKEN_START_ID, description);
        vm.expectEmit(true, true, false, false);
        emit SetForkPrice(CLAIM_TOKEN_START_ID, forkPrice);
        vm.expectEmit(true, true, true, false);
        emit Content(TRAVELOGGERS_OWNER, contentHash, content);
        vm.expectEmit(true, true, false, false);
        emit Publish(CLAIM_TOKEN_START_ID, contentHash);
        logbook.multicall(data);
    }

    /**
     * Donate, Fork
     */
    function testDonate(uint256 amount) public {
        _claimToTraveloggersOwner();

        // donate
        vm.deal(PUBLIC_SALE_MINTER, amount);
        vm.prank(PUBLIC_SALE_MINTER);
        if (amount > 0) {
            // uint256 contractBalance = address(this).balance;
            vm.expectEmit(true, true, true, false);
            emit Donate(CLAIM_TOKEN_START_ID, PUBLIC_SALE_MINTER, amount);
            logbook.donate{value: amount}(CLAIM_TOKEN_START_ID);
            // assertEq(address(this).balance, contractBalance + amount);
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

    function testDonateWithCommission(uint256 amount, uint256 bps) public {
        _claimToTraveloggersOwner();

        bool isInvalidBPS = bps > 10000 - _ROYALTY_BPS_LOGBOOK_OWNER;

        unchecked {
            if (amount * bps < amount && bps > 0) {
                return;
            }
        }

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
        logbook.donateWithCommission{value: 1 ether}(CLAIM_TOKEN_START_ID + 1, FRONTEND_OPERATOR, bps);
    }

    function testFork(string calldata content) public {
        _claimToTraveloggersOwner();

        uint256 amount = 1.342 ether;

        // no logbook
        vm.deal(PUBLIC_SALE_MINTER, 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("ERC721: operator query for nonexistent token");
        logbook.fork{value: 1 ether}(CLAIM_TOKEN_START_ID + 1, 0);

        // no content
        vm.deal(PUBLIC_SALE_MINTER, 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("no content");
        logbook.fork{value: 1 ether}(CLAIM_TOKEN_START_ID, 0);

        _publish(content);

        // value too small
        uint256 forkPrice = 0.1 ether;
        _setForkPrice(forkPrice);
        vm.deal(PUBLIC_SALE_MINTER, forkPrice);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("value too small");
        logbook.fork{value: forkPrice / 2}(CLAIM_TOKEN_START_ID, 0);

        _setForkPrice(amount);
        // uint256 contractBalance = address(this).balance;
        vm.deal(PUBLIC_SALE_MINTER, amount);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectEmit(true, true, true, true);
        emit Fork(CLAIM_TOKEN_START_ID, CLAIM_TOKEN_END_ID + 1, PUBLIC_SALE_MINTER, 0, amount);
        logbook.fork{value: amount}(CLAIM_TOKEN_START_ID, 0);
        // assertEq(address(this).balance, contractBalance + amount);
    }

    function testForkWithCommission(string calldata content, uint256 bps) public {
        uint256 amount = 1.342 ether;
        bool isInvalidBPS = bps > 10000 - _ROYALTY_BPS_LOGBOOK_OWNER;

        _claimToTraveloggersOwner();
        _publish(content);
        _setForkPrice(amount);

        vm.deal(PUBLIC_SALE_MINTER, amount);
        vm.prank(PUBLIC_SALE_MINTER);

        if (isInvalidBPS) {
            vm.expectRevert("invalid BPS");
        } else {
            vm.expectEmit(true, true, true, true);
            emit Fork(CLAIM_TOKEN_START_ID, CLAIM_TOKEN_END_ID + 1, PUBLIC_SALE_MINTER, 0, amount);
        }

        logbook.forkWithCommission{value: amount}(CLAIM_TOKEN_START_ID, 0, FRONTEND_OPERATOR, bps);
    }

    /**
     * Split Royalty, Withdraw
     */
    function testSplitRoyalty() public {
        uint256 forkPrice = 0.1 ether;
        uint256 logCount = 64;

        // no arithmetic overflow and underflow
        _claimToTraveloggersOwner();
        _setForkPrice(forkPrice);

        // append logs
        for (uint256 i = 0; i < logCount; i++) {
            // transfer to new owner
            address currentOwner = logbook.ownerOf(CLAIM_TOKEN_START_ID);
            address newOwner = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
            assertTrue(currentOwner != newOwner);
            vm.deal(currentOwner, forkPrice);
            vm.prank(currentOwner);
            logbook.transferFrom(currentOwner, newOwner, CLAIM_TOKEN_START_ID);

            // append log
            string memory content = string(abi.encodePacked(i));
            vm.deal(newOwner, forkPrice);
            vm.prank(newOwner);
            logbook.publish(CLAIM_TOKEN_START_ID, content);
        }

        // check logs
        (, bytes32[] memory contentHashes, address[] memory authors) = logbook.getLogbook(CLAIM_TOKEN_START_ID);
        assertEq(logCount, contentHashes.length);
        assertEq(logCount, authors.length);

        // fork
        vm.deal(PUBLIC_SALE_MINTER, forkPrice);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectEmit(true, true, true, true);
        emit Fork(CLAIM_TOKEN_START_ID, CLAIM_TOKEN_END_ID + 1, PUBLIC_SALE_MINTER, logCount, forkPrice);

        // check log count
        uint256 newTokenId = logbook.fork{value: forkPrice}(CLAIM_TOKEN_START_ID, logCount);
        (, bytes32[] memory forkedContentHashes, ) = logbook.getLogbook(newTokenId);
        assertEq(logCount, forkedContentHashes.length);

        // check content hashes
        string memory firstContent = string(abi.encodePacked(uint256(0)));
        bytes32 firstContentHash = keccak256(abi.encodePacked(firstContent));
        assertEq(firstContentHash, forkedContentHashes[0]);

        string memory lastContent = string(abi.encodePacked(uint256(logCount - 1)));
        bytes32 lastContentHash = keccak256(abi.encodePacked(lastContent));
        assertEq(lastContentHash, forkedContentHashes[logCount - 1]);

        // check owner balance
        address lastOwner = address(uint160(uint256(keccak256(abi.encodePacked(logCount - 1)))));
        uint256 feesLogbookOwner = (forkPrice * _ROYALTY_BPS_LOGBOOK_OWNER) / 10000;
        uint256 feesPerLogAuthor = (forkPrice - feesLogbookOwner) / logCount;
        uint256 lastOwnerBalance = logbook.getBalance(lastOwner);
        assertEq(lastOwnerBalance, feesLogbookOwner + feesPerLogAuthor);

        // check author balance
        address secondLastOwner = address(uint160(uint256(keccak256(abi.encodePacked(logCount - 2)))));
        uint256 secondLastOwnerBalance = logbook.getBalance(secondLastOwner);
        assertEq(secondLastOwnerBalance, feesPerLogAuthor);
    }

    function testWithdraw() public {
        uint256 donationValue = 3.13 ether;
        uint256 logCount = 64;

        // no arithmetic overflow and underflow
        _claimToTraveloggersOwner();

        // append logs
        for (uint256 i = 0; i < logCount; i++) {
            // transfer to new owner
            address currentOwner = logbook.ownerOf(CLAIM_TOKEN_START_ID);
            address newOwner = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
            assertTrue(currentOwner != newOwner);
            vm.prank(currentOwner);
            logbook.transferFrom(currentOwner, newOwner, CLAIM_TOKEN_START_ID);

            // append log
            string memory content = string(abi.encodePacked(i));
            vm.deal(newOwner, donationValue);
            vm.prank(newOwner);
            logbook.publish(CLAIM_TOKEN_START_ID, content);
        }

        // uint256 contractBalance = address(this).balance;

        // donate
        vm.deal(PUBLIC_SALE_MINTER, donationValue);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectEmit(true, true, true, false);
        emit Donate(CLAIM_TOKEN_START_ID, PUBLIC_SALE_MINTER, donationValue);
        logbook.donate{value: donationValue}(CLAIM_TOKEN_START_ID);

        // logbook owner withdrawl
        address owner = address(uint160(uint256(keccak256(abi.encodePacked(logCount - 1)))));
        uint256 feesLogbookOwner = (donationValue * _ROYALTY_BPS_LOGBOOK_OWNER) / 10000;
        uint256 feesPerLogAuthor = (donationValue - feesLogbookOwner) / logCount;
        uint256 ownerBalance = logbook.getBalance(owner);
        assertEq(ownerBalance, feesLogbookOwner + feesPerLogAuthor);

        uint256 ownerWalletBalance = owner.balance;
        vm.prank(owner);
        vm.expectEmit(true, true, false, false);
        emit Withdraw(owner, ownerBalance);
        logbook.withdraw();
        assertEq(owner.balance, ownerWalletBalance + ownerBalance);
        assertEq(logbook.getBalance(owner), 0);

        // uint256 contractBalanceAfterOwnerWithdraw = address(this).balance;
        // assertEq(contractBalanceAfterOwnerWithdraw, contractBalance - ownerWalletBalance - ownerBalance);

        // previous author withdrawl
        address secondLastOwner = address(uint160(uint256(keccak256(abi.encodePacked(logCount - 2)))));
        uint256 secondLastOwnerBalance = logbook.getBalance(secondLastOwner);
        assertEq(secondLastOwnerBalance, feesPerLogAuthor);

        uint256 secondLastOwnerWalletBalance = secondLastOwner.balance;
        vm.prank(secondLastOwner);
        vm.expectEmit(true, true, false, false);
        emit Withdraw(secondLastOwner, secondLastOwnerBalance);
        logbook.withdraw();
        assertEq(secondLastOwner.balance, secondLastOwnerWalletBalance + secondLastOwnerBalance);
        assertEq(logbook.getBalance(secondLastOwner), 0);
        // assertEq(address(this).balance, secondLastOwnerWalletBalance - feesPerLogAuthor);
    }
}
