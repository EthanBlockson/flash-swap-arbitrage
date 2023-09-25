// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./UniswapV2Interfaces.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

// SCENARIO AND GOAL EXAMPLE

// PEPE/USDC (0.90$), USDC/WETH (1.00$), PEPE/WETH (1.00$), USDC/USDT (1.00$)
// Borrowing USDC from USDC/USDT pair, Purchasing PEPE for USDC, Selling PEPE for WETH, Selling WETH for USDC and repaying debt

contract FlashSwapper is IUniswapV2Callee, Ownable {
    address public ROUTER;
    address public FACTORY;

    constructor(address _routerAddress, address _factoryAddress) {
        ROUTER = _routerAddress;
        FACTORY = _factoryAddress;
    }

    // Activate ability to receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    function flashSwapArbitrage(
        address _tokenBorrow, // e.g. USDC
        address _tokenBorrowPair, // e.g. USDT
        uint _borrowedAmount, // in wei, e.g. 5000000000000
        address _tokenWithProfit, // e.g. PEPE
        address _tokenWithProfitPair // e.g. WETH
    ) external {
        // check for approvals
        IERC20(_tokenBorrow).approve(address(ROUTER), type(uint256).max);
        IERC20(_tokenWithProfit).approve(address(ROUTER), type(uint256).max);
        IERC20(_tokenBorrowPair).approve(address(ROUTER), type(uint256).max);
        IERC20(_tokenWithProfitPair).approve(
            address(ROUTER),
            type(uint256).max
        );

        // define the pair for borrowing
        address pair = IUniswapV2Factory(FACTORY).getPair(
            _tokenBorrow,
            _tokenBorrowPair
        );
        require(pair != address(0), "!pair");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint amount0Out = _tokenBorrow == token0 ? _borrowedAmount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _borrowedAmount : 0;

        // define the data to pass to the uniswapV2Call
        bytes memory data = abi.encode(
            _tokenBorrow,
            _borrowedAmount,
            _tokenWithProfit,
            _tokenWithProfitPair
        );

        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    // called by pair contract
    function uniswapV2Call(
        address _sender,
        uint _amount0,
        uint _amount1,
        bytes calldata _data
    ) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(FACTORY).getPair(token0, token1);
        require(msg.sender == pair, "!pair");
        require(_sender == address(this), "!sender");

        (
            address tokenBorrow,
            uint borrowedAmount,
            address tokenWithProfit,
            address tokenWithProfitPair
        ) = abi.decode(_data, (address, uint, address, address));

        // NOOP to silence compiler "unused parameter" warning
        if (false) {
            _amount0;
            _amount1;
        }

        // about 0.3%
        uint fee = ((borrowedAmount * 3) / 997) + 1;
        uint amountToRepay = borrowedAmount + fee;

        // DO WHAT YOU WANT WITH BORROWED

        // swap borrowed for profit (e.g. USDC for PEPE)
        address[] memory profitPath = new address[](2);
        profitPath[0] = address(tokenBorrow);
        profitPath[1] = address(tokenWithProfit);

        IUniswapV2Router(ROUTER).swapExactTokensForTokens(
            borrowedAmount,
            0,
            profitPath,
            address(this),
            block.timestamp + 600
        );

        // sell profit in arbitrage pair (e.g. PEPE for WETH)
        uint pepeBalance = IERC20(tokenWithProfit).balanceOf(address(this));

        address[] memory profitToEthPath = new address[](2);
        profitToEthPath[0] = address(tokenWithProfit);
        profitToEthPath[1] = address(tokenWithProfitPair);

        IUniswapV2Router(ROUTER).swapExactTokensForTokens(
            pepeBalance,
            0,
            profitToEthPath,
            address(this),
            block.timestamp + 600
        );

        // swap arbitraged profit to borrowed (e.g. WETH for USDC)
        uint wethBalance = IERC20(tokenWithProfitPair).balanceOf(address(this));

        address[] memory wethToBorrowedPath = new address[](2);
        wethToBorrowedPath[0] = address(tokenWithProfitPair);
        wethToBorrowedPath[1] = address(tokenBorrow);

        IUniswapV2Router(ROUTER).swapExactTokensForTokens(
            wethBalance,
            0,
            wethToBorrowedPath,
            address(this),
            block.timestamp + 600
        );

        // END WHAT YOU WANT WITH BORROWED AND RETURN THE DEBT

        IERC20(tokenBorrow).transfer(pair, amountToRepay);

        // the profit will be left on this contract address
    }

    // Withdraw contract ether balance
    function withdrawEther(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    // Withdraw contract token balance
    function withdrawToken(address tokenAddress, address to) public onlyOwner {
        uint currentTokenBalance = IERC20(tokenAddress).balanceOf(
            address(this)
        );
        require(currentTokenBalance > 0, "Tokens amount must be > 0");
        IERC20(tokenAddress).transfer(to, currentTokenBalance);
    }
}
