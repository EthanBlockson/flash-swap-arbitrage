// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

contract PEPE is ERC20 {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address owner;
    address tokenAddress;
    address tokenUSDC;

    constructor(
        IUniswapV2Router02 _uniswapV2Router,
        address _tokenUSDC
    ) ERC20("PEPE", "PEPE") {
        uniswapV2Router = _uniswapV2Router;
        owner = msg.sender;
        tokenAddress = address(this);
        tokenUSDC = _tokenUSDC;
    }

    // Activate ability to recieve ETH
    receive() external payable {}

    // Init PEPE/WETH liquidity pool
    function initPoolWethPepe() public {
        require(msg.sender == owner, "Only owner can add initial liquidity");

        // Mint 0.0001 PEPE
        _mint(address(this), 100000000000000);

        // Check ether balance
        uint contractEtherBalance = address(this).balance;

        // Approve token transfer
        uint tokenAmount = IERC20(tokenAddress).balanceOf(address(this));
        require(tokenAmount > 0, "tokens amount must be > 0");
        IERC20(tokenAddress).approve(address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        IUniswapV2Router02(uniswapV2Router).addLiquidityETH{
            value: contractEtherBalance
        }(
            address(tokenAddress),
            tokenAmount,
            0,
            0,
            msg.sender,
            block.timestamp + 600
        );
    }

    // Init PEPE/USDC liquidity pool
    function initPoolPepeUsdc() public {
        require(msg.sender == owner, "Only owner can add initial liquidity");

        // Mint 0.0011 PEPE
        _mint(address(this), 1100000000000000);

        // Approve USDC transfers
        uint tokenAmountUSDC = IERC20(tokenUSDC).balanceOf(address(this));
        require(tokenAmountUSDC > 0, "tokens amount must be > 0");
        IERC20(tokenUSDC).approve(address(uniswapV2Router), tokenAmountUSDC);

        // Approve PEPE transfers
        uint tokenAmountPEPE = IERC20(tokenAddress).balanceOf(address(this));
        require(tokenAmountPEPE > 0, "tokens amount must be > 0");
        IERC20(tokenAddress).approve(address(uniswapV2Router), tokenAmountPEPE);

        // Add the liquidity
        IUniswapV2Router02(uniswapV2Router).addLiquidity(
            address(tokenAddress),
            address(tokenUSDC),
            tokenAmountPEPE,
            tokenAmountUSDC,
            0,
            0,
            msg.sender,
            block.timestamp + 600
        );
    }
}
