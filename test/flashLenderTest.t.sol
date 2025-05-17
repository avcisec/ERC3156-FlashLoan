// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {FlashBorrower} from "../src/FlashBorrower.sol";
import {FlashLender} from "../src/FlashLender.sol";
import {WETH} from "../src/utils/WETH.sol";

contract flashLenderTest is Test {

address public deployer = makeAddr("DEPLOYER");
address user = makeAddr("user");
uint256 constant DEPLOYER_STARTING_BALANCE = 1001 ether;
uint256 constant MINT_BALANCE = 1000 ether;
uint256 constant USER_STARTING_BALANCE = 1 ether;
uint256 constant BORROW_AMOUNT = 700 ether;
uint256 constant FEE = 1;
FlashLender flashLender;
FlashBorrower flashBorrower;
WETH weth;
address[] public supportedTokens;






    function setUp() public {

// deploy flashLender
    vm.deal(deployer, DEPLOYER_STARTING_BALANCE);
    vm.deal(user,USER_STARTING_BALANCE);

    vm.startPrank(deployer);
    weth = new WETH();
    supportedTokens.push(address(weth));
    weth.deposit{value: MINT_BALANCE}();
    flashLender = new FlashLender(supportedTokens, FEE);
    weth.approve(address(flashLender), MINT_BALANCE);
    weth.transfer(address(flashLender), MINT_BALANCE);
    vm.stopPrank();

// deploy flashBorrower
    vm.startPrank(user);
    flashBorrower = new FlashBorrower(flashLender);
    vm.stopPrank();

    }


    function testBorrowWeth() public {
        console.log("Is weth in supported token list?", flashLender.getSupportedTokens(address(weth)));

        vm.startPrank(address(flashBorrower));
        vm.stopPrank();
        vm.startPrank(user);
      
        flashBorrower.flashBorrow(address(weth), BORROW_AMOUNT);
        bool tx_success = flashBorrower.tx_success();
        console.log("tx status :", tx_success);
        assertEq(tx_success, true);

    }



}
