// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script} from "forge-std/Script.sol";
import {FlashBorrower} from "../src/FlashBorrower.sol";
import {FlashLender} from "../src/FlashLender.sol";
// import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {WETH} from "../src/utils/WETH.sol";



contract DeployFlashLender is Script {

address[] public supportedTokens;
WETH public weth;
uint256 public constant FEE = 1;
FlashLender lender;


function run() external returns(FlashLender) {
    weth = new WETH();
    supportedTokens.push(address(weth));
    vm.startBroadcast();
    lender = new FlashLender(supportedTokens, FEE);
    vm.stopBroadcast();
    vm.stopPrank();
    return lender;


}


}