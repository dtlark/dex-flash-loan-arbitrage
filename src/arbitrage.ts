import { generatePrimeSync } from "crypto";
//import { ethers } from "hardhat";
import coinpairs from './coinpairs.json'
//const axios = require('axios')

async function main() {

  //get contract info
  //const flashContract = await ethers.getContractFactory("Flash");
  //const contract = await flashContract.attach("0x57a6ee5f6Cc94ef013A2Ef0c5f6B127bE724fA16");
  
  //read token pairs from json
  var coinDict = {};
  let network: string = coinpairs.network;
  for (let i = 0; i < coinpairs.networks[network].length; i++) {
    coinDict[coinpairs.networks[network][i].address] = coinpairs.networks[network][i].token0;
  }

  // for each token pair 
  for (const [key, value] of Object.entries(coinDict)) {
    console.log(key, value);

    // get token pair price on each exchange
    const prices = [];
    for (let i = 0; i < coinpairs.routers.length; i++) {
      let price = await getPrice();  
      prices.push();
    }

    //find min and max //tournament method

    // if max - min - liquidity fees - gas price > threshold

      //borrow tokens from min price and sell to max
      //const swap = await contract.doSwap(token0, token1, amount0, uamount1, _pairAddress);
  }
}

// get token price from contract
async function getPrice() {

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

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

