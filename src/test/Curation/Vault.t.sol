// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {USDT} from "../utils/USDT.sol";
import {CurationVault} from "../../Curation/Vault.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract VaultTest is Test {
    using ECDSA for bytes32;

    error ZeroAddress();
    error ZeroAmount();
    error TransferFailed();
    error InvalidURI();
    error InvalidSignature();
    error Expired();
    error AlreadyWithdrawn();

    CurationVault internal vault;
    USDT internal usdt;

    event Curation(address indexed from, string indexed uid, IERC20 indexed token, string uri, uint256 amount);
    event Curation(address indexed from, string indexed uid, string uri, uint256 amount);
    event Withdraw(address indexed to, string indexed uid, IERC20 indexed token, uint256 amount);
    event Withdraw(address indexed to, string indexed uid, uint256 amount);
    event SignerChanged(address indexed newSigner);

    address constant DEPLOYER = address(176);
    address constant CURATOR = address(178);
    address constant OWNER = address(179);
    address constant RECIPIENT = address(180);

    address SIGNER;
    uint256 SIGNER_PRIVATE_KEY;

    uint256 constant MAX_CURATION_AMOUNT = 1000 ether;

    string constant CREATOR_UID = "creator1";
    string constant CONTENT_URI = "ipfs://content";

    function setUp() public {
        (address signer, uint256 signerPrivateKey) = makeAddrAndKey("signer");
        SIGNER = signer;
        SIGNER_PRIVATE_KEY = signerPrivateKey;

        vm.label(DEPLOYER, "DEPLOYER");
        vm.label(SIGNER, "SIGNER");
        vm.label(CURATOR, "CURATOR");
        vm.label(OWNER, "OWNER");
        vm.label(RECIPIENT, "RECIPIENT");

        // Deploy contracts
        vm.prank(DEPLOYER);
        vault = new CurationVault(SIGNER, OWNER);
        usdt = new USDT(CURATOR, 1000);

        // Setup curator
        vm.deal(CURATOR, MAX_CURATION_AMOUNT);
        vm.startPrank(CURATOR);
        usdt.approve(address(vault), type(uint256).max);
        vm.stopPrank();
    }

    function testERC20Curation(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= MAX_CURATION_AMOUNT);

        vm.expectEmit(true, true, true, true);
        emit Curation(CURATOR, CREATOR_UID, usdt, CONTENT_URI, amount);

        vm.prank(CURATOR);
        vault.curate(CREATOR_UID, usdt, amount, CONTENT_URI);

        assertEq(vault.erc20Balances(CREATOR_UID, address(usdt)), amount);
    }

    function testNativeCuration(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= MAX_CURATION_AMOUNT);

        vm.expectEmit(true, true, true, true);
        emit Curation(CURATOR, CREATOR_UID, CONTENT_URI, amount);

        vm.prank(CURATOR);
        vault.curate{value: amount}(CREATOR_UID, CONTENT_URI);

        assertEq(vault.nativeBalances(CREATOR_UID), amount);
    }

    function testCannotCurationInvalidURI() public {
        vm.expectRevert(InvalidURI.selector);
        vm.prank(CURATOR);
        vault.curate(CREATOR_UID, usdt, 10 ether, "");
    }

    function testCannotCurationZeroAmount() public {
        vm.expectRevert(ZeroAmount.selector);
        vm.prank(CURATOR);
        vault.curate(CREATOR_UID, usdt, 0, CONTENT_URI);
    }

    function testCannotCurationZeroNativeAmount() public {
        vm.expectRevert(ZeroAmount.selector);
        vm.prank(CURATOR);
        vault.curate{value: 0}(CREATOR_UID, CONTENT_URI);
    }

    function testCannotWithdrawZeroAddress() public {
        vm.expectRevert(ZeroAddress.selector);
        vault.withdraw(address(0), CREATOR_UID, usdt, 0, 0, bytes32(0), bytes32(0));
    }

    function testERC20Withdrawal(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= MAX_CURATION_AMOUNT);

        // Curate first
        vm.prank(CURATOR);
        vault.curate(CREATOR_UID, usdt, amount, CONTENT_URI);

        // Create signature
        uint256 expiry = block.timestamp + 1 hours;
        bytes32 hash = keccak256(abi.encodePacked(RECIPIENT, CREATOR_UID, usdt, expiry, address(vault)))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PRIVATE_KEY, hash);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(RECIPIENT, CREATOR_UID, usdt, amount);

        vault.withdraw(RECIPIENT, CREATOR_UID, usdt, expiry, v, r, s);

        assertEq(vault.erc20Balances(CREATOR_UID, address(usdt)), 0);
        assertEq(usdt.balanceOf(RECIPIENT), amount);
    }

    function testNativeWithdrawal(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= MAX_CURATION_AMOUNT);

        // Curate first
        vm.prank(CURATOR);
        vault.curate{value: amount}(CREATOR_UID, CONTENT_URI);

        // Create signature
        uint256 expiry = block.timestamp + 1 hours;
        bytes32 hash = keccak256(abi.encodePacked(RECIPIENT, CREATOR_UID, expiry, address(vault)))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PRIVATE_KEY, hash);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(RECIPIENT, CREATOR_UID, amount);

        vault.withdraw(RECIPIENT, CREATOR_UID, expiry, v, r, s);

        assertEq(vault.nativeBalances(CREATOR_UID), 0);
        assertEq(RECIPIENT.balance, amount);
    }

    function testCannotWithdrawExpired() public {
        uint256 expiry = block.timestamp - 1;
        bytes32 hash = keccak256(abi.encodePacked(RECIPIENT, CREATOR_UID, expiry, address(vault)))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PRIVATE_KEY, hash);

        vm.expectRevert(Expired.selector);
        vault.withdraw(RECIPIENT, CREATOR_UID, expiry, v, r, s);
    }

    function testCannotWithdrawInvalidSignature() public {
        uint256 expiry = block.timestamp + 1 hours;
        bytes32 hash = keccak256(abi.encodePacked(RECIPIENT, CREATOR_UID, expiry, address(vault)))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1234567, hash); // Wrong private key

        vm.expectRevert(InvalidSignature.selector);
        vault.withdraw(RECIPIENT, CREATOR_UID, expiry, v, r, s);
    }

    function testCannotWithdrawZeroAmount() public {
        uint256 expiry = block.timestamp + 1 hours;
        bytes32 hash = keccak256(abi.encodePacked(RECIPIENT, CREATOR_UID, expiry, address(vault)))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PRIVATE_KEY, hash);

        vm.expectRevert(ZeroAmount.selector);
        vault.withdraw(RECIPIENT, CREATOR_UID, expiry, v, r, s);
    }

    function testCannotWithdrawAlreadyWithdrawn() public {
        // Curate first
        uint256 amount = 1 ether;
        vm.prank(CURATOR);
        vault.curate{value: amount}(CREATOR_UID, CONTENT_URI);

        // Create signature
        uint256 expiry = block.timestamp + 1 hours;
        bytes32 hash = keccak256(abi.encodePacked(RECIPIENT, CREATOR_UID, expiry, address(vault)))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PRIVATE_KEY, hash);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(RECIPIENT, CREATOR_UID, amount);

        vault.withdraw(RECIPIENT, CREATOR_UID, expiry, v, r, s);

        assertEq(vault.nativeBalances(CREATOR_UID), 0);
        assertEq(RECIPIENT.balance, amount);

        // Try to withdraw again
        vm.expectRevert(AlreadyWithdrawn.selector);
        vault.withdraw(RECIPIENT, CREATOR_UID, expiry, v, r, s);
    }

    function testSetSigner() public {
        address newSigner = address(1234);

        vm.expectEmit(true, true, true, true);
        emit SignerChanged(newSigner);

        vm.prank(OWNER);
        vault.setSigner(newSigner);

        assertEq(vault.signer(), newSigner);
    }

    function testCannotSetZeroSigner() public {
        vm.expectRevert(ZeroAddress.selector);
        vm.prank(OWNER);
        vault.setSigner(address(0));
    }
}
