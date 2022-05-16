const hre = require("hardhat");
const { ethers } = require("ethers");

const { abi: IUniswapV3PoolABI } = require("@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json");
const { abi: QuoterABI } = require("@uniswap/v3-periphery/artifacts/contracts/lens/Quoter.sol/Quoter.json");

const { getAbi, getPoolImmutables } = require('./assist/helper')

require('dotenv').config()
const INFURA_URL = process.env.INFURA_URL //infura endpoint node
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY

const provider = new ethers.providers.JsonRpcProvider(INFURA_URL)
const poolAddress = "0x86f1d8390222a3691c28938ec7404a1661e618e0" //token pari
const quoterAddress = "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6" //address of the contract that gives price quote

async function main() {
  
  const inputAmount = 1;

  const poolContract = new ethers.Contract(poolAddress, IUniswapV3PoolABI, provider);
    //const protocalFee = await poolContract.protocalFees;
    //const fee = await poolContract.fee;

  const tokenAddress0 = await poolContract.token0();
  const tokenAddress1 = await poolContract.token1();
  
  var startTime = performance.now()
  const tokenAbi0 = await getAbi(tokenAddress0)
  var endTime = performance.now()

  console.log(`Call to doSomething took ${endTime - startTime} milliseconds`)

  const tokenAbi1 = await getAbi(tokenAddress1)

  const abi = [
    "function balanceOf(address owner) view returns (uint256)",
    "function decimals() view returns (uint8)",
    "function symbol() view returns (string)",
    "function transfer(address to, uint amount) returns (bool)",
    "event Transfer(address indexed from, address indexed to, uint amount)"
  ];

  const tokenContract0 = new ethers.Contract(tokenAddress0, abi, provider)
  const tokenContract1 = new ethers.Contract(tokenAddress1, abi, provider)

  const tokenSymbol0 = await tokenContract0.symbol()
  const tokenSymbol1 = await tokenContract1.symbol()

  const tokenDecimals0 = await tokenContract0.decimals()
  const tokenDecimals1 = await tokenContract1.decimals()

  const quoterContract = new ethers.Contract(quoterAddress, QuoterABI, provider)

  const immutables = await getPoolImmutables(poolContract)

  const amountIn = ethers.utils.parseUnits(inputAmount.toString(), tokenDecimals0) //string

  //callStatic = useful method that submits a state-changing transaction to an Ethereum node, but asks the node to simulate the state change, rather than to execute it.
  const quotedAmountOut = await quoterContract.callStatic.quoteExactInputSingle(
    immutables.token0,
    immutables.token1,
    immutables.fee,
    amountIn,
    0
  )

  const amountOut = ethers.utils.formatUnits(quotedAmountOut, tokenDecimals1)

  console.log(`${inputAmount} ${tokenSymbol0} can be swapped for ${amountOut} ${tokenSymbol1}`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
