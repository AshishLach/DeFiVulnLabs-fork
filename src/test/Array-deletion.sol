// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/*
Name: Array Deletion Oversight: leading to data inconsistency

Description:
In Solidity where improper deletion of elements from dynamic arrays can result in data inconsistency. 
When attempting to delete elements from an array, if the deletion process is not handled correctly, 
the array may still retain storage space and exhibit unexpected behavior. 


Mitigation:  
Option1: By copying the last element and placing it in the position to be removed.
Option2: By shifting them from right to left.

REF:
https://twitter.com/1nf0s3cpt/status/1677167550277509120
https://blog.solidityscan.com/improper-array-deletion-82672eed8e8d
https://github.com/sherlock-audit/2023-03-teller-judging/issues/88
*/

contract ContractTest is Test {
    ArrayDeletionBug ArrayDeletionBugContract;
    FixedArrayDeletion FixedArrayDeletionContract;

    function setUp() public {
        ArrayDeletionBugContract = new ArrayDeletionBug();
        FixedArrayDeletionContract = new FixedArrayDeletion();
    }

    function testArrayDeletion() public {
        assertEq(ArrayDeletionBugContract.getLength(), 5);
        ArrayDeletionBugContract.deleteElement(1);
        assertEq(ArrayDeletionBugContract.getLength(), 5);
    }

    function testArrayDeletionFixed() public {
        assertEq(FixedArrayDeletionContract.getLength(), 5);
        FixedArrayDeletionContract.deleteElement(1);
        assertEq(FixedArrayDeletionContract.getLength(), 4);
    }

    receive() external payable {}
}

contract ArrayDeletionBug {
    uint[] public myArray = [1, 2, 3, 4, 5];

    function deleteElement(uint index) external {
        require(index < myArray.length, "Invalid index");
        delete myArray[index];
    }

    function getLength() public view returns (uint) {
        return myArray.length;
    }
}

contract FixedArrayDeletion {
    uint[] public myArray = [1, 2, 3, 4, 5];

    //Mitigation 1: By copying the last element and placing it in the position to be removed.
    function deleteElement(uint index) external {
        require(index < myArray.length, "Invalid index");

        // Swap the element to be deleted with the last element
        myArray[index] = myArray[myArray.length - 1];

        // Delete the last element
        myArray.pop();
    }

    /*Mitigation 2: By shifting them from right to left.
    function deleteElement(uint index) external {
        require(index < myArray.length, "Invalid index");
        
        for (uint i = _index; i < myArray.length - 1; i++) {
            myArray[i] = myArray[i + 1];
        }
        
        // Delete the last element
        myArray.pop();
    }
    */
    function getLength() public view returns (uint) {
        return myArray.length;
    }
}
