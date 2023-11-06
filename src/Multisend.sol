// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract Multisend {
    function multisendEther(
        address[] calldata recipients,
        uint256[] calldata values
    ) external payable {
        // transfer ether to recipients
        for (uint256 i = 0; i < recipients.length; ) {
            payable(recipients[i]).transfer(values[i]);
            unchecked {
                ++i;
            }
        }
        // return excess ether to sender
        uint256 balance = address(this).balance;
        if (balance > 0) payable(msg.sender).transfer(balance);
    }

    function multisendToken(
        IERC20 token,
        address[] calldata recipients,
        uint256[] calldata values
    ) external {
        // calculate total amount of tokens to transfer
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; ) {
            total += values[i];
            unchecked {
                ++i;
            }
        }
        // transfer tokens to this contract
        require(token.transferFrom(msg.sender, address(this), total));
        // transfer tokens to recipients
        for (uint256 i = 0; i < recipients.length; ) {
            require(token.transfer(recipients[i], values[i]));
            unchecked {
                ++i;
            }
        }
    }
}
