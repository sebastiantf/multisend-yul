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
        assembly {
            if recipients.length {
                // end = start of recipients array + length * 32 bytes
                let end := add(recipients.offset, shl(5, recipients.length)) // shl by 5 is the same as mul by 32

                // offsets of first recipient and value
                let recipientOffset := recipients.offset
                let valueOffset := values.offset

                // infinite loop with break at end
                for {

                } 1 {

                } {
                    if iszero(
                        call(
                            gas(),
                            calldataload(recipientOffset),
                            calldataload(valueOffset),
                            0,
                            0,
                            0,
                            0
                        )
                    ) {
                        revert(0, 0)
                    }

                    recipientOffset := add(recipientOffset, 0x20)
                    valueOffset := add(valueOffset, 0x20)

                    if iszero(lt(recipientOffset, end)) {
                        break
                    }
                }

                // return excess ether to sender
                if gt(balance(address()), 0) {
                    if iszero(
                        call(gas(), caller(), balance(address()), 0, 0, 0, 0)
                    ) {
                        revert(0, 0)
                    }
                }
            }
        }
    }

    function multisendToken(
        IERC20 token,
        address[] calldata recipients,
        uint256[] calldata values
    ) external {
        // calculate total amount of tokens to transfer
        uint256 total = 0;
        assembly {
            if recipients.length {
                // end = start of recipients array + length * 32 bytes
                let end := add(recipients.offset, shl(5, recipients.length)) // shl by 5 is the same as mul by 32

                // offsets of first recipient and value
                let recipientOffset := recipients.offset
                let valueOffset := values.offset

                // infinite loop with break at end
                for {

                } 1 {

                } {
                    total := add(total, calldataload(valueOffset))

                    recipientOffset := add(recipientOffset, 0x20)
                    valueOffset := add(valueOffset, 0x20)

                    if iszero(lt(recipientOffset, end)) {
                        break
                    }
                }
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
