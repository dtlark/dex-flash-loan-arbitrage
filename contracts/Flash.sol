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

    uint timeout; // timeout for flashloan completion

    //uniswap factory address
    address public factory;

    //create pointer to the sushiswapRouter
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
        // make sure the pair exists in uniswap 
        require(pairAddress != address(0), "Pool not found on Uniswap!!!");
        IUniswapV2Pair(pairAddress).swap(amount0, amount1, address(this), bytes("1")); 
        //if data.length equals 0, the contract assumes that payment has already been received, and simply transfers the tokens to the to address. But, if data.length is greater than 0, the contract transfers the tokens and then calls uniswapV2Call
    }

    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {

        // the path is the array of addresses to capture pricing information 
        address[] memory path = new address[](2); 
        
        // get the amount of tokens that were borrowed in the flash loan amount 0 or amount 1 
        // call it amountTokenBorrowed and will use later in the function 
        uint amountTokenBorrowed = _amount0 == 0 ? _amount1 : _amount0; 

        // get the addresses of the two tokens from the uniswap liquidity pool 
        address token0 = IUniswapV2Pair(msg.sender).token0(); 
        address token1 = IUniswapV2Pair(msg.sender).token1(); 

        // make sure the call to this function originated from
        // one of the pair contracts in uniswap to prevent unauthorized behavior
        require(msg.sender == UniswapV2Library.pairFor(factory, token0, token1), 'Invalid Request');

        // make sure one of the amounts = 0 
        require(_amount0 == 0 || _amount1 == 0);

        // create and populate path array for sushiswap.  
        // this defines what token we are buying or selling 
        // if amount0 == 0 then we are going to sell token 1 and buy token 0 on sushiswap 
        // if amount0 is not 0 then we are going to sell token 0 and buy token 1 on sushiswap 
        path[0] = _amount0 == 0 ? token1 : token0; 
        path[1] = _amount0 == 0 ? token0 : token1; 

        // create a pointer to the token we are going to sell on sushiswap 
        
 
        IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
        
        // approve the sushiSwapRouter to spend our tokens so the trade can occur             
        token.approve(address(sushiSwapRouter), amountTokenBorrowed);

        // calculate the amount of tokens we need to reimburse uniswap for the flashloan 
        uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountTokenBorrowed, path)[0]; 
        
        // finally sell the token we borrowed from uniswap on sushiswap 
        // amountTokenBorrowed is the amount to sell 
        // amountRequired is the minimum amount of token to receive in exchange required to payback the flash loan 
        // path what we are selling or buying 
        // msg.sender address to receive the tokens 
        // deadline is the order time limit 
        // if the amount received does not cover the flash loan the entire transaction is reverted 
        uint amountReceived = sushiSwapRouter.swapExactTokensForTokens( amountTokenBorrowed, amountRequired, path, msg.sender, timeout)[1]; 

        // pointer to output token from sushiswap 
        IERC20 outputToken = IERC20(_amount0 == 0 ? token0 : token1);
        
        // amount to payback flashloan 
        // amountRequired is the amount we need to payback 
        // uniswap can accept any token as payment
        outputToken.transfer(msg.sender, amountRequired);   

        // send profit (remaining tokens) back to the address that initiated the transaction 
        outputToken.transfer(tx.origin, amountReceived - amountRequired);  
        
    }


}