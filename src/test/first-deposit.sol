// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*

Name: First deposit bug

Description:
First pool depositor can be front-run and have part of their deposit stolen
In this case, we can control the variable "_supplied." 
By depositing a small amount of loan tokens to obtain pool tokens, 
we can front-run other depositors' transactions and inflate the price of pool tokens through a substantial "donation."
Consequently, the attacker can withdraw a greater quantity of loan tokens than they initially possessed.

This calculation issue arises because, in Solidity, if the pool token value for a user becomes less than 1,
it is essentially rounded down to 0.

Mitigation:  
Consider minting a minimal amount of pool tokens during the first deposit 
and sending them to zero address, this increases the cost of the attack. 
Uniswap V2 solved this problem by sending the first 1000 LP tokens to the zero address. 
The same can be done in this case i.e. when totalSupply() == 0, 
send the first min liquidity LP tokens to the zero address to enable share dilution.

REF:
https://defihacklabs.substack.com/p/solidity-security-lesson-2-first
https://github.com/sherlock-audit/2023-02-surge-judging/issues/1
https://github.com/transmissions11/solmate/issues/178
*/

contract ContractTest is Test {
    SimplePool SimplePoolContract;
    MyToken MyTokenContract;

    function setUp() public {
        MyTokenContract = new MyToken();
        SimplePoolContract = new SimplePool(address(MyTokenContract));
    }

    function testFirstDeposit() public {
        address alice = vm.addr(1);
        address bob = vm.addr(2);
        MyTokenContract.transfer(alice, 1 ether + 1);
        MyTokenContract.transfer(bob, 2 ether);
        vm.startPrank(alice);
        MyTokenContract.approve(address(SimplePoolContract), type(uint256).max);
        SimplePoolContract.deposit(1 ether + 1);
        // MyTokenContract.transfer(address(SimplePoolContract), 1 ether);
        vm.stopPrank();
        console.log(
            "total shares alice holds now",
            SimplePoolContract.balanceOf(alice)
        );

        vm.startPrank(bob);
        MyTokenContract.approve(address(SimplePoolContract), type(uint256).max);
        SimplePoolContract.deposit(2 ether);
        vm.stopPrank();
        console.log(
            "total shares bob holds now",
            SimplePoolContract.balanceOf(bob)
        );
        //Ideally bob should have more shares

        vm.startPrank(alice);
        uint256 aliceBalanceBefore = MyTokenContract.balanceOf(alice);

        SimplePoolContract.withdraw(1);
        uint256 aliceBalanceAfter = MyTokenContract.balanceOf(alice);

        vm.stopPrank();
        console.log("Alice deposited only  1 ether 1 wei");

        console.log(
            "total Profit of Alice",
            aliceBalanceAfter - aliceBalanceBefore
        );

        vm.startPrank(bob);
        uint256 bobBalanceBefore = MyTokenContract.balanceOf(bob);

        SimplePoolContract.withdraw(1);
        uint256 bobBalanceAfter = MyTokenContract.balanceOf(bob);

        vm.stopPrank();
        console.log("Alice deposited 2 ethers");

        console.log("total Profit of Bob", bobBalanceAfter - bobBalanceBefore);
    }

    receive() external payable {}
}

contract MyToken is ERC20, Ownable {
    constructor() ERC20("MyToken", "MTK") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract SimplePool {
    IERC20 public loanToken;
    uint public totalShares;

    mapping(address => uint) public balanceOf;

    constructor(address _loanToken) {
        loanToken = IERC20(_loanToken);
    }

    function deposit(uint amount) external {
        require(amount > 0, "Amount must be greater than zero");

        uint _shares;
        if (totalShares == 0) {
            // _shares = amount;
            balanceOf[address(0)] += 1000;
            totalShares += 1000;
            // _totalSupply -= 1000;
            _shares = tokenToShares(
                amount,
                loanToken.balanceOf(address(this)),
                totalShares,
                false
            );
        } else {
            _shares = tokenToShares(
                amount,
                loanToken.balanceOf(address(this)),
                totalShares,
                false
            );
        }

        require(
            loanToken.transferFrom(msg.sender, address(this), amount),
            "TransferFrom failed"
        );
        balanceOf[msg.sender] += _shares;
        totalShares += _shares;
    }

    function tokenToShares(
        uint _tokenAmount,
        uint _supplied,
        uint _sharesTotalSupply,
        bool roundUpCheck
    ) internal pure returns (uint) {
        if (_supplied == 0) return _tokenAmount;

        /*


_tokenAmount : 1
_sharesTotalSupply: 1000
supplied: 1000

Alice: 1 share 
Alice supplied  1 ether extra
--------------------------
_tokenAmount : 2 ether
 _sharesTotalSupply: 1001
        supplied:  1 ether + 1001

Bob:  2001


--------------

what if  alice provided 1 ether+1 in the deposit intialuy?
_tokenAmount : 1 ether + 1
_sharesTotalSupply: 1000
supplied: 1000

Alice total shares : (10000000000000000001 * 1000) / 1000

        */
        uint shares = (_tokenAmount * _sharesTotalSupply) / _supplied;
        if (
            roundUpCheck &&
            shares * _supplied < _tokenAmount * _sharesTotalSupply
        ) shares++;
        return shares;
    }

    function withdraw(uint shares) external {
        require(shares > 0, "Shares must be greater than zero");
        require(balanceOf[msg.sender] >= shares, "Insufficient balance");

        uint tokenAmount = (shares * loanToken.balanceOf(address(this))) /
            totalShares;

        balanceOf[msg.sender] -= shares;
        totalShares -= shares;

        require(loanToken.transfer(msg.sender, tokenAmount), "Transfer failed");
    }
}
