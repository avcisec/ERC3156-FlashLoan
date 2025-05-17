// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IERC20} from "./interfaces/IERC20.sol";
import {IERC3156FlashBorrower} from "./interfaces/IERC3156FlashBorrower.sol";
import {IERC3156FlashLender} from "./interfaces/IERC3156FlashLender.sol";

contract FlashBorrower is IERC3156FlashBorrower {
    error flashBorrower__UntrustedLender(address lender);
    error flashBorrower__UntrustedLoanInitiator(address initiator);
    bool public tx_success = false;

    enum Action {
        NORMAL,
        OTHER
    }

    IERC3156FlashLender lender;

    constructor(IERC3156FlashLender _lender) {
        lender = _lender;
    }

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        returns (bytes32)
    {
        require(msg.sender == address(lender), flashBorrower__UntrustedLender(msg.sender));
        require(initiator == address(this), flashBorrower__UntrustedLoanInitiator(address(this)));
        (Action action) = abi.decode(data, (Action));

        if (action == Action.NORMAL) {
            tx_success = true;
        }

        if (action == Action.OTHER) {}

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function flashBorrow(address token, uint256 amount) public {
        bytes memory data = abi.encode(Action.NORMAL);
        IERC20(token).approve(address(lender), amount);
        uint256 allowance = IERC20(token).allowance(address(this), address(lender));
        uint256 fee = lender.flashFee(token, amount);
        uint256 repayment = amount + fee;
        IERC20(token).approve(address(lender), allowance + repayment);
        lender.flashLoan(IERC3156FlashBorrower(this), token, amount, data);

    }
}
