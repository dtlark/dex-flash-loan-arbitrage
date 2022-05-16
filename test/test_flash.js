const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Flash", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Flash = await ethers.getContractFactory("Flash");
    const flash = await Flash.deploy();
    await flash.deployed();
    console.log("Time:", flash.timeout);

  });
});
