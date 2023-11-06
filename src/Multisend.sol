// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Multisend {
    function multisendEther(
        address[] calldata recipients,
        uint256[] calldata values
    ) external payable {
        assembly {
            if recipients.length {
                /* transfer ether to recipients */
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

                /* return excess ether to sender */
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
        address token,
        address[] calldata recipients,
        uint256[] calldata values
    ) external {
        assembly {
            if recipients.length {
                /* calculate total amount of tokens to transfer */
                let total := 0

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

                /* transfer total tokens to this contract */
                // prepare calldata
                mstore(0x00, hex"23b872dd") // transferFrom(address from, address to, uint256 amount)
                mstore(0x04, caller()) // msg.sender
                mstore(0x24, address()) // this contract
                mstore(0x44, total)

                if iszero(call(gas(), token, 0, 0, 0x64, 0, 0)) {
                    revert(0, 0)
                }

                /* transfer tokens to recipients */
                // offsets of first recipient and value
                recipientOffset := recipients.offset
                valueOffset := values.offset

                // infinite loop with break at end
                for {

                } 1 {

                } {
                    /* transfer total tokens to this contract */
                    // prepare calldata
                    mstore(0x00, hex"a9059cbb") // transfer(address to, uint256 value)
                    mstore(0x04, calldataload(recipientOffset))
                    mstore(0x24, calldataload(valueOffset))

                    if iszero(call(gas(), token, 0, 0, 0x44, 0, 0)) {
                        revert(0, 0)
                    }

                    recipientOffset := add(recipientOffset, 0x20)
                    valueOffset := add(valueOffset, 0x20)

                    if iszero(lt(recipientOffset, end)) {
                        break
                    }
                }
            }
        }
    }
}
