// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.11;

import "hardhat/console.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol"; //>=0.5.0;
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol"; //>=0.5.0;
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol"; // >=0.5.0
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IERC20.sol"; //^0.8.0

contract Ownable {    

    address private _owner;

    constructor() public {
        _owner = msg.sender;
    }

    function owner() public view returns(address) {
        return _owner;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Not the owner");
        _; 
    }
}

contract Flash is Ownable {

    uint private timeout; // timeout for flashloan completion
    address public factory;

    //pointer to sushiswapRouter
    IUniswapV2Router02 public sushiSwapRouter;

    constructor() public {
        factory = 0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;  
        sushiSwapRouter = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
        timeout = block.timestamp + 100;
    }

    function getTime() public view returns (uint) {
        console.log("Time: ", timeout);
        return timeout;
    }

    function flashLoan(address token0, address token1, uint amount0, uint amount1) external {
        
        address pairAddress = IUniswapV2Factory(factory).getPair(token0, token1); 
        // require pair exist in uniswap 
        require(pairAddress != address(0), "Pool not found on Uniswap!!!");
        IUniswapV2Pair(pairAddress).swap(amount0, amount1, address(this), bytes("1")); 
        //if data.length equals 0, the contract assumes that payment has already been received, and simply transfers the tokens to the to address. But, if data.length is greater than 0, the contract transfers the tokens and then calls uniswapV2Call
    }

    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {

        address[] memory path = new address[](2); 
        uint amountTokenBorrowed = _amount0 == 0 ? _amount1 : _amount0; 

        address token0 = IUniswapV2Pair(msg.sender).token0(); 
        address token1 = IUniswapV2Pair(msg.sender).token1(); 

        require(msg.sender == UniswapV2Library.pairFor(factory, token0, token1), 'You are not the owner!!');
        require(_amount0 == 0 || _amount1 == 0);

        path[0] = _amount0 == 0 ? token1 : token0; 
        path[1] = _amount0 == 0 ? token0 : token1; 
 
        IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
              
        token.approve(address(sushiSwapRouter), amountTokenBorrowed);

        uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountTokenBorrowed, path)[0]; 
        uint amountReceived = sushiSwapRouter.swapExactTokensForTokens( amountTokenBorrowed, amountRequired, path, msg.sender, timeout)[1]; 

        IERC20 outputToken = IERC20(_amount0 == 0 ? token0 : token1);
        outputToken.transfer(msg.sender, amountRequired);   

        outputToken.transfer(tx.origin, amountReceived - amountRequired);  
    }

}