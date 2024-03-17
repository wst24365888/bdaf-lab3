// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConstantPriceAMM {
    // The addresses of the two ERC20 tokens
    address public token0;
    address public token1;

    // The fixed conversion rate between token0 and token1
    uint256 public conversionRate;

    // Keeps track of the liquidity provided by each user
    mapping(address => uint256) public providedLiquidity;

    // Constructor to initialize the contract with the token addresses and conversion rate
    constructor(address _token0, address _token1, uint256 _conversionRate) {
        token0 = _token0;
        token1 = _token1;
        conversionRate = _conversionRate;
    }

    // Function to swap between the two tokens
    function trade(address tokenFrom, uint256 fromAmount) external {
        // Ensure that the token being traded is either token0 or token1
        require(tokenFrom == token0 || tokenFrom == token1, "Invalid token");

        address tokenTo;
        uint256 toAmount;

        // Calculate the amount of the other token to be received based on the conversion rate
        if (tokenFrom == token0) {
            tokenTo = token1;
            toAmount = fromAmount * 10000 / conversionRate;
        } else if (tokenFrom == token1) {
            tokenTo = token0;
            toAmount = fromAmount * conversionRate / 10000;
        }

        // Ensure that the user has enough balance of the token being traded
        require(IERC20(tokenFrom).balanceOf(msg.sender) >= fromAmount, "Insufficient balance");
        // Ensure that the contract has enough balance of the other token
        require(IERC20(tokenTo).balanceOf(address(this)) >= toAmount, "Insufficient liquidity");

        // Transfer the tokens from the user to the contract
        IERC20(tokenFrom).transferFrom(msg.sender, address(this), fromAmount);

        // Transfer the other token from the contract to the user
        IERC20(tokenTo).transfer(msg.sender, toAmount);
    }

    // Function to provide liquidity to the pool
    function provideLiquidity(uint256 token0Amount, uint256 token1Amount) external {
        // Get the current balances of the two tokens in the contract
        uint256 token0Balance = IERC20(token0).balanceOf(address(this));
        uint256 token1Balance = IERC20(token1).balanceOf(address(this));

        // Calculate the actual amounts of tokens to be added to the pool
        uint256 actualToken0Amount;
        uint256 actualToken1Amount;

        // If there is no existing liquidity, add the provided amounts
        if (token0Balance == 0 && token1Balance == 0) {
            actualToken0Amount = token0Amount;
            actualToken1Amount = token1Amount;
        }
        // If there is no existing balance of token0, add only token1
        else if (token0Balance == 0) {
            actualToken0Amount = 0;
            actualToken1Amount = token1Amount;
        }
        // If there is no existing balance of token1, add only token0
        else if (token1Balance == 0) {
            actualToken0Amount = token0Amount;
            actualToken1Amount = 0;
        }
        // Otherwise, calculate the amounts based on the current ratio
        else {
            if (token0Amount * token1Balance > token1Amount * token0Balance) {
                actualToken0Amount = token1Amount * token0Balance / token1Balance;
                actualToken1Amount = token1Amount;
            } else {
                actualToken0Amount = token0Amount;
                actualToken1Amount = token0Amount * token1Balance / token0Balance;
            }
        }

        // Ensure that the user has enough balance of both tokens
        require(IERC20(token0).balanceOf(msg.sender) >= actualToken0Amount, "Insufficient balance of token0");
        require(IERC20(token1).balanceOf(msg.sender) >= actualToken1Amount, "Insufficient balance of token1");

        // Transfer the tokens from the user to the contract
        IERC20(token0).transferFrom(msg.sender, address(this), actualToken0Amount);
        IERC20(token1).transferFrom(msg.sender, address(this), actualToken1Amount);

        // Update the provided liquidity for the user
        providedLiquidity[msg.sender] += actualToken0Amount + actualToken1Amount * conversionRate / 10000;
    }

    // Function to withdraw liquidity from the pool
    function withdrawLiquidity() external {
        // Get the current balances of the two tokens in the contract
        uint256 token0Balance = IERC20(token0).balanceOf(address(this));
        uint256 token1Balance = IERC20(token1).balanceOf(address(this));

        // Calculate the total liquidity in the pool
        uint256 totalLiquidity = token0Balance + token1Balance * conversionRate / 10000;

        // Calculate the ratio of the user's liquidity to the total liquidity
        uint256 liquidityRatio = providedLiquidity[msg.sender] / totalLiquidity;

        // Transfer the user's share of tokens to the user
        IERC20(token0).transfer(msg.sender, token0Balance * liquidityRatio);
        IERC20(token1).transfer(msg.sender, token1Balance * liquidityRatio);

        // Reset the user's provided liquidity
        providedLiquidity[msg.sender] = 0;
    }
}