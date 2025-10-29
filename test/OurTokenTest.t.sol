// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Test, console} from "forge-std/Test.sol";
import {OurToken} from "src/OurToken.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 1000 ether;

    function setUp() public {
        ourToken = new OurToken(STARTING_BALANCE);
    }

    function testInitialSupply() public {
        uint256 totalSupply = ourToken.totalSupply();
        assertEq(totalSupply, STARTING_BALANCE);
    }

    function testTokenNameAndSymbol() public {
        string memory name = ourToken.name();
        string memory symbol = ourToken.symbol();
        assertEq(name, "OurToken");
        assertEq(symbol, "OTK");
    }

    function testBalanceOfDeployer() public {
        uint256 balance = ourToken.balanceOf(address(this));
        assertEq(balance, 1000 ether);
    }

    function testTransfer() public {
        uint256 transferAmount = 100 ether;

        bool success = ourToken.transfer(bob, transferAmount);
        assertTrue(success, "transfer should return true");
        uint256 bobBalance = ourToken.balanceOf(bob);
        uint256 senderBalance = ourToken.balanceOf(address(this));

        assertEq(bobBalance, transferAmount);
        assertEq(senderBalance, STARTING_BALANCE - transferAmount);
    }

    function testTransferInsufficientBalance() public {
        // We are trying to send more tokens than the test contract has.
        uint256 currentBalance = ourToken.balanceOf(address(this));
        uint256 transferAmount = currentBalance + 1;
 
        // We expect the transaction to revert with a specific custom error.
        // The error provides the sender, their balance, and the amount they tried to send.
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                address(this), // sender
                currentBalance, // balance
                transferAmount // amount
            )
        );
        ourToken.transfer(bob, transferAmount);
    }

        function testTransferToZeroAddress() public {
        uint256 transferAmount = 100 ether;

        // Expect the `ERC20InvalidReceiver` custom error, providing the invalid address as the argument.
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidReceiver.selector, address(0)
            )
        );
        ourToken.transfer(address(0), transferAmount);
    }

        function testTransferFrom() public {
        uint256 transferAmount = 100 ether;
        // 1. The test contract first sends tokens to Bob, so he has something to spend.
        ourToken.transfer(bob, STARTING_BALANCE);

        // 2. We use vm.prank() to simulate the next call coming from Bob.
        // Bob approves the test contract (address(this)) to spend `transferAmount` of his tokens.
        vm.prank(bob);
        ourToken.approve(address(this), transferAmount);

        // 3. The test contract (the spender) now calls transferFrom to move tokens
        // from Bob (the owner) to Alice (the recipient).
        bool success = ourToken.transferFrom(bob, alice, transferAmount);
        assertTrue(success, "transferFrom should return true");

        // 4. Check the final balances.
        uint256 aliceBalance = ourToken.balanceOf(alice);
        uint256 bobBalance = ourToken.balanceOf(bob);
        uint256 deployerBalance = ourToken.balanceOf(address(this));
        console.log("Deployer balance:", deployerBalance);
        console.log("Alice balance:", aliceBalance);
        console.log("Bob balance:", bobBalance);

        assertEq(aliceBalance, transferAmount);
        assertEq(bobBalance, STARTING_BALANCE - transferAmount);
        // The deployer/test contract balance should be 0, as it sent all its tokens to Bob.
        assertEq(deployerBalance, 0);
    }

        function testTransferFromInsufficientAllowance() public {
        uint256 transferAmount = 100 ether;

        // We expect the transaction to revert with the insufficient allowance custom error.
        // The spender is the test contract (address(this)).
        // The current allowance is 0.
        // The needed amount is transferAmount.
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                address(this), // spender
                0, // current allowance
                transferAmount // needed amount
            )
        );
        ourToken.transferFrom(address(this), alice, transferAmount);
    }

    function testTransferFromZeroAddress() public {
        uint256 transferAmount = 100 ether;

        // In `transferFrom`, the allowance is checked before the sender's address.
        // Since the allowance for address(0) is always 0, this is the error that will be thrown first.
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                address(this), // spender
                0, // current allowance
                transferAmount // needed amount
            )
        );
        ourToken.transferFrom(address(0), alice, transferAmount);
    }

    function testApprove() public {
        uint256 approveAmount = 200 ether;

        bool success = ourToken.approve(bob, approveAmount);
        assertTrue(success, "approve should return true");

        uint256 allowance = ourToken.allowance(address(this), bob);
        assertEq(allowance, approveAmount);
    }

    function testAllowanceWorks() public {
        uint256 approveAmount = 150 ether;
        

        ourToken.approve(bob, approveAmount);
        uint256 allowance = ourToken.allowance(address(this), bob);
        assertEq(allowance, approveAmount);
    }   

} 
