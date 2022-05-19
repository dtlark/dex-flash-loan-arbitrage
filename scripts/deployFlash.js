const hre = require("hardhat");

async function main() {

  const Flash = await hre.ethers.getContractFactory("Flash");
  const flash = await Flash.deploy();

  await flash.deployed();

  console.log("Deployed to:", Flash.address);
  console.log("Time:", flash.timeout);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
