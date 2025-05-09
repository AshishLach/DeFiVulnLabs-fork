// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/*
Name: Precision Issues - Divide before multiply

Description:
The contracts demonstrate a common issue when performing division operations in Solidity, 
as Solidity doesn't support floating-point numbers. The order of operations can affect the result due to integer truncation.

In the Miscalculation contract, the function price performs the division before the
multiplication (price / 100) * discount. Due to the fact that Solidity truncates integers
when dividing, the result of price / 100 will be 0 if the price is less than 100. 
This causes the result of the multiplication to be 0 as well.

On the other hand, in the Calculation contract, the function price performs the multiplication
before the division (price * discount) / 100. This way, the result will be correct as the multiplication
doesn't get truncated, only the final result does.

Mitigation:Always perform multiplication before division to avoid losing precision.

REF:
https://twitter.com/1nf0s3cpt/status/1599774264437395461
https://blog.solidityscan.com/precision-loss-in-arithmetic-operations-8729aea20be9

*/
contract ContractTest is Test {
    Miscalculation MiscalculationContract;
    Calculation CalculationContract;

    function testMiscalculation() public {
        MiscalculationContract = new Miscalculation();
        assertEq(MiscalculationContract.price(250, 80), 200);
    }

    function testCalculationFixed() public {
        CalculationContract = new Calculation();
        assertEq(CalculationContract.price(250, 80), 200);
    }
}

contract Miscalculation {
    function price(
        uint256 price,
        uint256 discount
    ) public pure returns (uint256) {
        return (price / 100) * discount; // wrong calculation
    }
}

contract Calculation {
    function price(
        uint256 price,
        uint256 discount
    ) public pure returns (uint256) {
        return (price * discount) / 100; // correct calculation
    }
}
