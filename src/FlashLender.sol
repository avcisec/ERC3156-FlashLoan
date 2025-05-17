// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/*//////////////////////////////////////////////////////////////
                                IMPORTS
    //////////////////////////////////////////////////////////////*/

import {IERC3156FlashLender} from "./interfaces/IERC3156FlashLender.sol";
import {IERC3156FlashBorrower} from "./interfaces/IERC3156FlashBorrower.sol";
import {IERC20} from "./interfaces/IERC20.sol";

/*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

error flashLender__UnsupportedToken(address token);
error flashLender__TransferFailed();
error flashLender__CallbackFailed();
error flashLender__RepayFailed();

contract FlashLender is IERC3156FlashLender {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public fee = 1;
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    mapping(address => uint256) public feeForToken;
    mapping(address => bool) public supportedTokens;

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(address[] memory _supportedTokens, uint256 _fee) {
        for (uint256 i = 0; i > _supportedTokens.length; i++) {
            supportedTokens[_supportedTokens[i]] = true;
        }

        fee = _fee;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setFee(address token, uint256 newFee) public {
        feeForToken[token] = newFee;
    }

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool)
    {
        require(supportedTokens[token], flashLender__UnsupportedToken(token));
        fee = _flashFee(token, amount);
        require(IERC20(token).transfer(address(receiver), amount), flashLender__TransferFailed());
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == CALLBACK_SUCCESS,
            flashLender__CallbackFailed()
        );
        require(IERC20(token).transferFrom(address(receiver), address(this), amount + fee), flashLender__RepayFailed());
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _flashFee(address token, uint256 amount) internal view returns (uint256) {
        return (amount * fee) / 10000;
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256) {
        return supportedTokens[token] ? IERC20(token).balanceOf(address(this)) : 0;
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256) {
        require(supportedTokens[token], flashLender__UnsupportedToken(token));

        return _flashFee(token, amount);
    }

    function getSupportedTokens(address token) external view returns (bool) {
        bool tokenStatus = supportedTokens[token];

        return tokenStatus;

    }
}
