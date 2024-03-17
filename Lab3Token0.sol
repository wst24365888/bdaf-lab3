// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Lab3Token0 is ERC20 {
    constructor() ERC20("Lab3Token0", "L3T0") {
        // Mint 100,000,000 tokens to the contract deployer
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
