// SCENARIO AND GOAL EXAMPLE

// PEPE/USDC (0.90$), USDC/WETH (1.00$), PEPE/WETH (1.00$), USDC/USDT (1.00$)
// Borrowing USDC from USDC/USDT pair, Purchasing PEPE for USDC, Selling PEPE for WETH, Selling WETH for USDC and repaying debt

// deploy USDC
// deploy PEPE
// deploy USDT
// deploy FlashSwapper
// transfer 0.0001 ether to USDC
// transfer 0.0001 ether to PEPE
// mint 0.00009 USDC to PEPE contract
// mint 0.0001 USDC to USDT contract
// initPoolWethUsdc WETH/USDC from owner of USDC (0.0001 USDC will be minted)
// initPoolWethPepe WETH/PEPE from owner of PEPE (0.0001 PEPE will be minted)
// initPoolPepeUsdc PEPE/USDC from owner of PEPE (0.0011 PEPE will be minted) and 0.00009 USDC
// initPoolUsdtUsdc USDT/USDC from owner of USDT (0.0001 USDT will be minted) and 0.0001 USDC
// perform arbitrage flash swap (for 0.000005 USDC in wei)
// withdraw the profit form contract (0.00002168 USDC)

// SCRIPT FOR THE ALCHEMY GOERLI TESTNET

const hre = require("hardhat")

// Import UniswapV2Router02.sol
const routerArtifact = require('@uniswap/v2-periphery/build/UniswapV2Router02.json')

async function main() {
    // Get addresses from config's imported private keys
    const [owner] = await hre.ethers.getSigners()

    // Initialize UniswapV2Router02.sol
    const routerAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D" // TEMP, GOERLI
    const factoryAddress = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f" // TEMP, GOERLI
    const deadAddress = "0x000000000000000000000000000000000000dEaD"
    const uniswapRouter = await ethers.getContractAt(routerArtifact.abi, routerAddress)
    // Read the WETH address
    let wethAddress = await uniswapRouter.WETH()
    console.log("WETH address:", wethAddress)
    // Define swap deadline
    const deadline = Date.now() + 600

    // Deploy USDC.sol
    // Init factory
    const USDC = await ethers.getContractFactory('USDC') // Contract.json name here
    // Push to constructor and go
    const usdc = await USDC.deploy(
        routerAddress
    )
    console.log('USDC address:', usdc.target)

    // Deploy PEPE.sol
    // Init factory
    const PEPE = await ethers.getContractFactory('PEPE') // Contract.json name here
    // Push to constructor and go
    const pepe = await PEPE.deploy(
        routerAddress,
        usdc.target
    )
    console.log('PEPE address:', pepe.target)

    // Deploy USDT.sol
    // Init factory
    const USDT = await ethers.getContractFactory('USDT') // Contract.json name here
    // Push to constructor and go
    const usdt = await USDT.deploy(
        routerAddress,
        usdc.target
    )
    console.log('USDT address:', usdt.target)

    // Deploy FlashSwapper.sol
    // Init factory
    const FlashSwapper = await ethers.getContractFactory('FlashSwapper') // Contract.json name here
    // Push to constructor and go
    const flashswapper = await FlashSwapper.deploy(
        routerAddress,
        factoryAddress
    )
    console.log('FlashSwapper address:', flashswapper.target)

    // Transfer ETH to USDC to init LP WETH/USDC
    const ethForUSDC = ethers.parseEther("0.0001")
    const sendETHToUSDC = await owner.sendTransaction({
        to: usdc.target,
        value: ethForUSDC // amount of wei as string
    })
    await sendETHToUSDC.wait()
    console.log(ethers.formatEther(ethForUSDC), "ETH transferred to USDC contract")

    // Transfer ETH to PEPE to init LP WETH/PEPE
    const ethForPEPE = ethers.parseEther("0.0001")
    const sendETHForPepe = await owner.sendTransaction({
        to: pepe.target,
        value: ethForPEPE // amount of wei as string
    })
    await sendETHForPepe.wait()
    console.log(ethers.formatEther(ethForPEPE), "ETH transferred to PEPE contract")

    // Mint 0.00009 USDC to PEPE contract
    const mintUSDCtoPEPE = await usdc.connect(owner).mintMoreUSDC(
        pepe.target,
        90000000000000
    )
    await mintUSDCtoPEPE.wait()
    console.log("0.00009 USDC minted to PEPE contract")

    // Mint 0.0001 USDC to USDT contract
    const mintUSDCtoUSDT = await usdc.connect(owner).mintMoreUSDC(
        usdt.target,
        100000000000000
    )
    await mintUSDCtoUSDT.wait()
    console.log("0.0001 USDC minted to USDT contract")

    // Init pool WETH/USDC
    const initPoolWethUsdc = await usdc.connect(owner).initPoolWethUsdc()
    await initPoolWethUsdc.wait()
    console.log("WETH/USDC LP created")

    // Init pool WETH/PEPE
    const initPoolWethPepe = await pepe.connect(owner).initPoolWethPepe()
    await initPoolWethPepe.wait()
    console.log("WETH/PEPE LP created")

    // Init pool PEPE/USDC
    const initPoolPepeUsdc = await pepe.connect(owner).initPoolPepeUsdc()
    await initPoolPepeUsdc.wait()
    console.log("PEPE/USDC LP created")

    // Init pool USDT/USDC
    const initPoolUsdtUsdc = await usdt.connect(owner).initPoolUsdtUsdc()
    await initPoolUsdtUsdc.wait()
    console.log("USDT/USDC LP created")

    // Call flashSwapArbitrage
    const flashSwapArbitrage = await flashswapper.connect(owner).flashSwapArbitrage(
        usdc.target,
        usdt.target,
        5000000000000,
        pepe.target,
        wethAddress
    )
    await flashSwapArbitrage.wait()
    console.log("Arbitrage swap was successfull")

    // Withdraw token from contract address
    const withdrawToken = await flashswapper.connect(owner).withdrawToken(
        usdc.target,
        deadAddress
    )
    await withdrawToken.wait()
    console.log("Token can be withdrawed from contract")

    console.log("Done")
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

// HINTS
// Put await function.wait() after the functions that strictly depending of previous function completion
// Use console.log(constName.hash) to log hash of tx