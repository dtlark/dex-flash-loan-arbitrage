//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "./UniswapV2Interfaces.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Flash is IUniswapV2Callee {
    address public owner;
    uint256 public balance;

    IUniswapV2Factory constant uniswapV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); // same for all networks

    constructor() {
        owner = msg.sender;
    }

    receive() external payable { //only sends ether
        balance += msg.value;
    }

    function withdraw(uint amount) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= balance, "Insufficient funds");

        bool success = payable(owner).send(amount);
        require(success, "Send failed");
        balance -= amount;
    }

    function transferERC20(IERC20 token, address to, uint256 amount) public {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "Insufficient funds");
        token.transfer(to, amount);
    }

    function doSwap(address token0, address token1, uint amount0, uint amount1, address _pairAddress) external {
        require(_pairAddress != address(0), "Token pair does not exist"); //token pair exists
        IUniswapV2Pair(_pairAddress).swap(amount0, amount1, address(this), bytes("Flash"));
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        //TODO
    }
}