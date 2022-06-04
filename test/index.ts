import { expect } from "chai";
import { ethers } from "hardhat";

describe("Flash Test", function () {
  it("Should return the new greeting once it's changed", async function () {
    
    const Greeter = await ethers.getContractFactory("Flash");
    const greeter = await Greeter.deploy();
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
