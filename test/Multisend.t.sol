pragma solidity 0.8.19;

import {Multisend} from "./../src/Multisend.sol";
import {Token} from "./Token.sol";
import "forge-std/Test.sol";

contract MultisendTest is Test {
    Multisend multisend;
    Token token;
    address user = vm.addr(0x1337);
    uint256 totalTokens = 1000;
    uint256 totalEther = totalTokens * 0.001 ether;

    function setUp() public {
        token = new Token();
        token.transfer(user, totalTokens);
        multisend = new Multisend();
    }

    function test_multisendToken() public {
        vm.startPrank(user);
        token.approve(address(multisend), totalTokens);

        address[] memory recipients = new address[](totalTokens);
        uint256[] memory amounts = new uint256[](totalTokens);
        for (uint256 i = 0; i < totalTokens; i++) {
            recipients[i] = vm.addr(i + 1);
            amounts[i] = 1;
        }
        multisend.multisendToken(address(token), recipients, amounts);
        vm.stopPrank();

        for (uint256 i = 0; i < totalTokens; i++) {
            assertEq(token.balanceOf(recipients[i]), 1);
        }
    }

    function test_multisendEther() public {
        payable(user).transfer(totalEther);
        vm.startPrank(user);

        address[] memory recipients = new address[](totalTokens);
        uint256[] memory amounts = new uint256[](totalTokens);
        for (uint256 i = 0; i < totalTokens; i++) {
            recipients[i] = vm.addr(i + 1);
            amounts[i] = 0.001 ether;
        }

        multisend.multisendEther{value: totalEther}(recipients, amounts);
        vm.stopPrank();

        for (uint256 i = 0; i < totalTokens; i++) {
            assertEq(address(recipients[i]).balance, 0.001 ether);
        }
        assertEq(address(multisend).balance, 0);
        assertEq(address(user).balance, 0);
    }

    function test_multisendEtherShouldTransferExcessEth() public {
        payable(user).transfer(totalEther + 100 wei);
        vm.startPrank(user);

        address[] memory recipients = new address[](totalTokens);
        uint256[] memory amounts = new uint256[](totalTokens);
        for (uint256 i = 0; i < totalTokens; i++) {
            recipients[i] = vm.addr(i + 1);
            amounts[i] = 0.001 ether;
        }

        // send 100 wei more than needed
        multisend.multisendEther{value: totalEther + 100 wei}(
            recipients,
            amounts
        );
        vm.stopPrank();

        for (uint256 i = 0; i < totalTokens; i++) {
            assertEq(address(recipients[i]).balance, 0.001 ether);
        }
        assertEq(address(multisend).balance, 0);
        assertEq(address(user).balance, 100 wei);
    }

    function test_multisendEtherCompareGaslite() public {
        payable(user).transfer(totalEther);
        vm.startPrank(user);

        address[] memory recipients = new address[](totalTokens);
        uint256[] memory amounts = new uint256[](totalTokens);
        for (uint256 i = 0; i < totalTokens; i++) {
            recipients[i] = vm.addr(2);
            amounts[i] = 0.001 ether;
        }

        multisend.multisendEther{value: totalEther}(recipients, amounts);
        vm.stopPrank();
    }
}
