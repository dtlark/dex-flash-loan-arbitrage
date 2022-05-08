const hre = require("hardhat");

async function main() {

    const contract = await hre.ethers.getContractFactory("DEXSwap");
    const contractDep = await smartContract.deploy();
  
    await contractDep.deployed();
  
    console.log("Deployed to:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});