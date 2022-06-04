import { ethers } from "hardhat";

async function main() {
  const Greeter = await ethers.getContractFactory("Flash");
  const greeter = await Greeter.deploy();

  await greeter.deployed();
  console.log("Flash deployed to:", greeter.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
