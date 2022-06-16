import { ethers } from "hardhat";
const axios = require('axios')

async function main() {

  const flashContract = await ethers.getContractFactory("Flash");

  const contract = await flashContract.attach("0x57a6ee5f6Cc94ef013A2Ef0c5f6B127bE724fA16");

  console.log("Flash deployed to:", contract.address);

  const own = await contract.owner();
  console.log("Flash owner:", own);
    
  const bal = await contract.balance();
  console.log("Flash balance:", bal);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
