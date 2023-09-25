// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

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

contract USDT is ERC20 {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address owner;
    address tokenAddress;
    address tokenUSDC;

    constructor(
        IUniswapV2Router02 _uniswapV2Router,
        address _tokenUSDC
    ) ERC20("USDT", "USDT") {
        uniswapV2Router = _uniswapV2Router;
        owner = msg.sender;
        tokenAddress = address(this);
        tokenUSDC = _tokenUSDC;
        _mint(address(owner), 100000000000000);
    }

    // Activate ability to recieve ETH
    receive() external payable {}

    // Init USDT/USDC liquidity pool
    function initPoolUsdtUsdc() public {
        require(msg.sender == owner, "Only owner can add initial liquidity");

        // Mint 0.0001 USDT
        _mint(address(this), 100000000000000);

        // Approve USDC transfers
        uint tokenAmountUSDC = IERC20(tokenUSDC).balanceOf(address(this));
        require(tokenAmountUSDC > 0, "tokens amount must be > 0");
        IERC20(tokenUSDC).approve(address(uniswapV2Router), tokenAmountUSDC);

        // Approve USDT transfers
        uint tokenAmountUSDT = IERC20(tokenAddress).balanceOf(address(this));
        require(tokenAmountUSDT > 0, "tokens amount must be > 0");
        IERC20(tokenAddress).approve(address(uniswapV2Router), tokenAmountUSDT);

        // Add the liquidity
        IUniswapV2Router02(uniswapV2Router).addLiquidity(
            address(tokenAddress),
            address(tokenUSDC),
            tokenAmountUSDT,
            tokenAmountUSDC,
            0,
            0,
            msg.sender,
            block.timestamp + 600
        );
    }

    function mintMoreUSDT(address to) public {
        // Mint 0.0001 USDT
        _mint(address(to), 100000000000000);
    }
}
