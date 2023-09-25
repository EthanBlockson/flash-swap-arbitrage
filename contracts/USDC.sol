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
}

contract USDC is ERC20 {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address owner;
    address tokenAddress;

    constructor(IUniswapV2Router02 _uniswapV2Router) ERC20("USDC", "USDC") {
        uniswapV2Router = _uniswapV2Router;
        owner = msg.sender;
        tokenAddress = address(this);
        _mint(address(owner), 100000000000000);
    }

    // Activate ability to recieve ETH
    receive() external payable {}

    // Init USDC/WETH liquidity pool
    function initPoolWethUsdc() public {
        require(msg.sender == owner, "Only owner can add initial liquidity");

        // Mint 0.0001 USDC
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

    function mintMoreUSDC(address to, uint amount) public {
        _mint(address(to), amount);
    }
}
