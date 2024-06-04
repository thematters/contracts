//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {USDT} from "../utils/USDT.sol";
import {Acceptor, Rejector} from "./Receivers.sol";
import {Vault as VaultContract} from "../../Curation/Vault.sol";
import {IVault} from "../../Curation/IVault.sol";

contract VaultTest is Test {
    using ECDSA for bytes32;

    VaultContract internal vault;
    USDT internal usdt;
    Acceptor internal contractAcceptor;
    Rejector internal contractRejector;

    address public DEPLOYER;
    address public OWNER;
    address public CREATOR;
    address public CURATOR;
    address public ATTACKER;
    address public APPROVED;

    uint256 public DEPLOYER_PK;

    function setUp() public {
        // label addresses
        (DEPLOYER, DEPLOYER_PK) = makeAddrAndKey("DEPLOYER");
        (OWNER, ) = makeAddrAndKey("OWNER");
        (CREATOR, ) = makeAddrAndKey("CREATOR");
        (CURATOR, ) = makeAddrAndKey("CURATOR");
        (ATTACKER, ) = makeAddrAndKey("ATTACKER");
        (APPROVED, ) = makeAddrAndKey("APPROVED");

        // deploy Vault contract
        vm.prank(DEPLOYER);
        vault = new VaultContract(DEPLOYER, OWNER);

        // deploy ERC-20 token
        usdt = new USDT(CURATOR, 1000);
        assertEq(usdt.balanceOf(CURATOR), 1000 * (10 ** uint256(usdt.decimals())));
        assertEq(usdt.balanceOf(CREATOR), 0);
        vm.prank(CURATOR);
        usdt.approve(address(vault), type(uint256).max);

        // deploy receiver contracts
        contractAcceptor = new Acceptor();
        contractRejector = new Rejector();

        // fund curator
        vm.deal(CURATOR, 100 ether);
    }

    function depositETH(uint256 amount, bytes32 _vaultId) public {
        vm.prank(CURATOR);
        vault.deposit{value: amount}(_vaultId);
    }

    function depositERC20(uint256 amount, bytes32 _vaultId) public {
        vm.prank(CURATOR);
        vault.deposit(_vaultId, address(usdt), amount);
    }

    /**
     * Deposit: Native Token
     */
    function testNativeTokenDeposit() public {
        uint256 _amount = 1 ether;
        uint256 _curatorBalance = CURATOR.balance;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));

        vm.expectEmit(true, true, true, true);
        emit IVault.Deposited(_vaultId, _amount, CURATOR);

        vm.prank(CURATOR);
        vault.deposit{value: _amount}(_vaultId);

        // will affect ETH balances
        assertEq(CURATOR.balance, _curatorBalance - _amount);
        assertEq(vault.balances(_vaultId), _amount);
        assertEq(vault.claimed(_vaultId), 0);

        // wont affect ERC-20 balances
        assertEq(vault.erc20Balances(_vaultId, address(0)), 0);
        assertEq(vault.erc20Claimed(_vaultId, address(0)), 0);
    }

    function testCannotNativeTokenDepositIfZeroAmount() public {
        uint256 _amount = 0;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));

        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));
        vm.prank(CURATOR);
        vault.deposit{value: _amount}(_vaultId);
    }

    /**
     * Deposit: ERC-20 Token
     */
    function testErc20TokenDeposit() public {
        uint256 _amount = 100;
        uint256 _curatorBalance = usdt.balanceOf(CURATOR);
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));

        vm.expectEmit(true, true, true, true);
        emit IVault.Deposited(_vaultId, address(usdt), _amount, CURATOR);

        vm.prank(CURATOR);
        vault.deposit(_vaultId, address(usdt), _amount);

        assertEq(usdt.balanceOf(CURATOR), _curatorBalance - _amount);
        assertEq(vault.erc20Balances(_vaultId, address(usdt)), _amount);
        assertEq(vault.erc20Claimed(_vaultId, address(usdt)), 0);

        // wont affect ETH balances
        assertEq(vault.balances(_vaultId), 0);
        assertEq(vault.claimed(_vaultId), 0);
    }

    function testCannotErc20TokenDepositIfZeroAmount() public {
        uint256 _amount = 0;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));

        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));
        vm.prank(CURATOR);
        vault.deposit(_vaultId, address(usdt), _amount);
    }

    function testCannotErc20TokenDepositIfNotApproval() public {
        uint256 _amount = 100;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));

        vm.expectRevert("ERC20: insufficient allowance");
        vm.prank(ATTACKER);
        vault.deposit(_vaultId, address(usdt), _amount);
    }

    /**
     * Claim: Native Token
     */
    function testNativeTokenClaim() public {
        uint256 _amount = 1 ether;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));
        uint256 _creatorBalance = CREATOR.balance;

        uint256 _expiredAt = block.timestamp + 1 days;

        // first claim
        bytes32 _digest = keccak256(abi.encodePacked(_vaultId, CREATOR, _expiredAt, block.chainid, address(vault)))
            .toEthSignedMessageHash();
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(DEPLOYER_PK, _digest);

        depositETH(_amount, _vaultId);

        vm.expectEmit(true, true, true, true);
        emit IVault.Claimed(_vaultId, CREATOR, _amount);

        vm.prank(CREATOR);
        vault.claim(_vaultId, CREATOR, _expiredAt, _v, _r, _s);

        assertEq(CREATOR.balance, _creatorBalance + _amount);
        assertEq(vault.balances(_vaultId), _amount);
        assertEq(vault.claimed(_vaultId), _amount);
        assertEq(vault.available(_vaultId), 0);

        // second claim
        _expiredAt = block.timestamp + 2 days;
        _digest = keccak256(abi.encodePacked(_vaultId, CREATOR, _expiredAt, block.chainid, address(vault)))
            .toEthSignedMessageHash();
        (_v, _r, _s) = vm.sign(DEPLOYER_PK, _digest);

        depositETH(_amount, _vaultId);

        vm.expectEmit(true, true, true, true);
        emit IVault.Claimed(_vaultId, CREATOR, _amount);

        vm.prank(CREATOR);
        vault.claim(_vaultId, CREATOR, _expiredAt, _v, _r, _s);

        assertEq(CREATOR.balance, _creatorBalance + _amount * 2);
        assertEq(vault.balances(_vaultId), _amount * 2);
        assertEq(vault.claimed(_vaultId), _amount * 2);
        assertEq(vault.available(_vaultId), 0);
    }

    function testCannotNativeTokenClaimIfZeroBalance() public {
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));
        uint256 _expiredAt = block.timestamp + 1 days;
        bytes32 _digest = keccak256(abi.encodePacked(_vaultId, CREATOR, _expiredAt, block.chainid, address(vault)))
            .toEthSignedMessageHash();
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(DEPLOYER_PK, _digest);

        vm.expectRevert(abi.encodeWithSignature("ZeroBalance()"));
        vm.prank(CREATOR);
        vault.claim(_vaultId, CREATOR, _expiredAt, _v, _r, _s);
    }

    function testCannotNativeTokenClaimIfExpired() public {
        uint256 _amount = 1 ether;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));

        uint256 _expiredAt = block.timestamp - 1;
        bytes32 _digest = keccak256(abi.encodePacked(_vaultId, CREATOR, _expiredAt, block.chainid, address(vault)))
            .toEthSignedMessageHash();
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(DEPLOYER_PK, _digest);

        depositETH(_amount, _vaultId);

        vm.expectRevert(abi.encodeWithSignature("ClaimExpired()"));
        vm.prank(CREATOR);
        vault.claim(_vaultId, CREATOR, _expiredAt, _v, _r, _s);
    }

    function testCannotNativeTokenClaimIfInvalidSignature() public {
        uint256 _amount = 1 ether;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));

        uint256 _expiredAt = block.timestamp + 1 days;
        bytes32 _digest = keccak256(abi.encodePacked(_vaultId, CREATOR, _expiredAt, block.chainid, address(vault)))
            .toEthSignedMessageHash();
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(DEPLOYER_PK, _digest);

        depositETH(_amount, _vaultId);

        vm.expectRevert(abi.encodeWithSignature("InvalidSignature()"));
        vm.prank(ATTACKER);
        vault.claim(_vaultId, ATTACKER, _expiredAt, _v, _r, _s);
    }

    function testCannotNativeTokenClaimIfAlreadyClaimed() public {
        uint256 _amount = 1 ether;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));

        uint256 _expiredAt = block.timestamp + 1 days;
        bytes32 _digest = keccak256(abi.encodePacked(_vaultId, CREATOR, _expiredAt, block.chainid, address(vault)))
            .toEthSignedMessageHash();
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(DEPLOYER_PK, _digest);

        depositETH(_amount, _vaultId);

        vm.expectEmit(true, true, true, true);
        emit IVault.Claimed(_vaultId, CREATOR, _amount);

        vm.prank(CREATOR);
        vault.claim(_vaultId, CREATOR, _expiredAt, _v, _r, _s);

        depositETH(_amount, _vaultId);

        vm.expectRevert(abi.encodeWithSignature("AlreadyClaimed()"));
        vm.prank(CREATOR);
        vault.claim(_vaultId, CREATOR, _expiredAt, _v, _r, _s);
    }

    /**
     * Claim: ERC-20 Token
     */
    function testErc20TokenClaim() public {
        uint256 _amount = 100;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));
        uint256 _creatorBalance = usdt.balanceOf(CREATOR);

        uint256 _expiredAt = block.timestamp + 1 days;
        bytes32 _digest = keccak256(
            abi.encodePacked(_vaultId, address(usdt), CREATOR, _expiredAt, block.chainid, address(vault))
        ).toEthSignedMessageHash();
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(DEPLOYER_PK, _digest);

        depositERC20(_amount, _vaultId);

        vm.expectEmit(true, true, true, true);
        emit IVault.Claimed(_vaultId, address(usdt), CREATOR, _amount);

        vm.prank(CREATOR);
        vault.claim(_vaultId, address(usdt), CREATOR, _expiredAt, _v, _r, _s);

        assertEq(usdt.balanceOf(CREATOR), _creatorBalance + _amount);
        assertEq(vault.erc20Balances(_vaultId, address(usdt)), _amount);
        assertEq(vault.erc20Claimed(_vaultId, address(usdt)), _amount);
        assertEq(vault.available(_vaultId, address(usdt)), 0);
    }

    function testCannotErc20TokenClaimIfZeroBalance() public {
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));
        uint256 _expiredAt = block.timestamp + 1 days;
        bytes32 _digest = keccak256(
            abi.encodePacked(_vaultId, address(usdt), CREATOR, _expiredAt, block.chainid, address(vault))
        ).toEthSignedMessageHash();
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(DEPLOYER_PK, _digest);

        vm.expectRevert(abi.encodeWithSignature("ZeroBalance()"));
        vm.prank(CREATOR);
        vault.claim(_vaultId, address(usdt), CREATOR, _expiredAt, _v, _r, _s);
    }

    function testCannotErc20TokenClaimIfExpired() public {
        uint256 _amount = 100;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));

        uint256 _expiredAt = block.timestamp - 1;
        bytes32 _digest = keccak256(
            abi.encodePacked(_vaultId, address(usdt), CREATOR, _expiredAt, block.chainid, address(vault))
        ).toEthSignedMessageHash();
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(DEPLOYER_PK, _digest);

        depositERC20(_amount, _vaultId);

        vm.expectRevert(abi.encodeWithSignature("ClaimExpired()"));
        vm.prank(CREATOR);
        vault.claim(_vaultId, address(usdt), CREATOR, _expiredAt, _v, _r, _s);
    }

    function testCannotErc20TokenClaimIfInvalidSignature() public {
        uint256 _amount = 100;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));

        uint256 _expiredAt = block.timestamp + 1 days;
        bytes32 _digest = keccak256(
            abi.encodePacked(_vaultId, address(usdt), CREATOR, _expiredAt, block.chainid, address(vault))
        ).toEthSignedMessageHash();
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(DEPLOYER_PK, _digest);

        depositERC20(_amount, _vaultId);

        vm.expectRevert(abi.encodeWithSignature("InvalidSignature()"));
        vm.prank(ATTACKER);
        vault.claim(_vaultId, address(usdt), ATTACKER, _expiredAt, _v, _r, _s);
    }

    function testCannotErc20TokenClaimIfAlreadyClaimed() public {
        uint256 _amount = 100;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));

        uint256 _expiredAt = block.timestamp + 1 days;
        bytes32 _digest = keccak256(
            abi.encodePacked(_vaultId, address(usdt), CREATOR, _expiredAt, block.chainid, address(vault))
        ).toEthSignedMessageHash();
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(DEPLOYER_PK, _digest);

        depositERC20(_amount, _vaultId);

        vm.expectEmit(true, true, true, true);
        emit IVault.Claimed(_vaultId, address(usdt), CREATOR, _amount);

        vm.prank(CREATOR);
        vault.claim(_vaultId, address(usdt), CREATOR, _expiredAt, _v, _r, _s);

        depositERC20(_amount, _vaultId);

        vm.expectRevert(abi.encodeWithSignature("AlreadyClaimed()"));
        vm.prank(CREATOR);
        vault.claim(_vaultId, address(usdt), CREATOR, _expiredAt, _v, _r, _s);
    }

    /**
     * Sweep
     */
    function testNativeTokenSweep() public {
        uint256 _amount = 1 ether;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));
        uint256 _ownerBalance = OWNER.balance;

        depositETH(_amount, _vaultId);

        vm.expectEmit(true, true, true, true);
        emit IVault.Swept(OWNER, _amount);

        vm.prank(OWNER);
        vault.sweep(OWNER);

        assertEq(OWNER.balance, _ownerBalance + _amount);
        assertEq(vault.balances(_vaultId), _amount);
        assertEq(vault.claimed(_vaultId), 0);
        assertEq(vault.available(_vaultId), _amount);
    }

    function testErc20TokenSweep() public {
        uint256 _amount = 100;
        bytes32 _vaultId = keccak256(abi.encodePacked(CREATOR));
        uint256 _ownerBalance = usdt.balanceOf(OWNER);

        depositERC20(_amount, _vaultId);

        vm.expectEmit(true, true, true, true);
        emit IVault.Swept(address(usdt), OWNER, _amount);

        vm.prank(OWNER);
        vault.sweep(address(usdt), OWNER);

        assertEq(usdt.balanceOf(OWNER), _ownerBalance + _amount);
        assertEq(vault.erc20Balances(_vaultId, address(usdt)), _amount);
        assertEq(vault.erc20Claimed(_vaultId, address(usdt)), 0);
        assertEq(vault.available(_vaultId, address(usdt)), _amount);
    }

    function testSetSigner() public {
        address _signer = address(0x1234567890123456789012345678901234567890);

        vm.expectEmit(true, true, true, true);
        emit IVault.SignerChanged(_signer);

        vm.prank(OWNER);
        vault.setSigner(_signer);

        assertEq(vault.signer(), _signer);
    }

    function testCannotSetSignerByAttacker() public {
        address _signer = address(0x1234567890123456789012345678901234567890);

        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(ATTACKER);
        vault.setSigner(_signer);
    }

    function testCannotSetSignerIfZeroAddress() public {
        address _signer = address(0);

        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));

        vm.prank(OWNER);
        vault.setSigner(_signer);
    }
}
