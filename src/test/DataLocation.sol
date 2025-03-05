// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/*
Name: Data Location Confusion Vulnerability

Description:
Misuse of storage and memory references of the user in the updaterewardDebt function.

The function updaterewardDebt is updating the rewardDebt value of a UserInfo struct 
that is stored in memory. The issue is that this won't persist between function calls. 
As soon as the function finishes executing, the memory is cleared and the changes are lost.

Mitigation:
Ensure the correct usage of memory and storage in the function parameters. Make all the locations explicit.

REF:
https://mudit.blog/cover-protocol-hack-analysis-tokens-minted-exploit/
https://www.educative.io/answers/storage-vs-memory-in-solidity

*/

contract ContractTest is Test {
    Array ArrayContract;

    function testDataLocation() public {
        ArrayContract = new Array();
        ArrayContract.updaterewardDebt(1000);

        (uint256 amount, uint256 rewardDebt) = ArrayContract.userInfo(
            address(this)
        );
        //Still it will be zero even through 1000 was set
        assertEq(amount, 0);
    }

    receive() external payable {}
}

contract Array is Test {
    mapping(address => UserInfo) public userInfo; // storage

    struct UserInfo {
        uint256 amount; // How many tokens got staked by user.
        uint256 rewardDebt; // Reward debt. See Explanation below.
    }

    function updaterewardDebt(uint amount) public {
        UserInfo memory user = userInfo[msg.sender]; // memory, vulnerable point
        user.rewardDebt = amount;
    }

    function fixedupdaterewardDebt(uint amount) public {
        UserInfo storage user = userInfo[msg.sender]; // storage
        user.rewardDebt = amount;
    }
}
