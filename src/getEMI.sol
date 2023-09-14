//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {getInvestorProposal} from "./getInvestorProposal.sol";

/*
 * @title getEMI
 * @author Abhijay Paliwal
 * 
 * The contract is responsible to calculate and receive EMI from borrower
 *
 */

contract getEMI {
    uint principal;
    uint interestRate;
    uint time;
    address borrower;
    address[] investors;
    address debtTokenContract;
    uint EMILeft; // months of EMI to be paid
    uint penalty; // penalty paid by borrower for late payment, in % per day
    uint public constant thirtyDayEpoch = 2629743;
    uint public nextEpochToPay = 2629743 + block.timestamp;

    constructor(
        uint _principal,
        uint _interestRate,
        uint _time,
        address _borrower,
        address[] memory _investors,
        address _debtTokenContract
    ) {
        principal = _principal;
        interestRate = _interestRate * 1000;
        time = _time;
        borrower = _borrower;
        _debtTokenContract = debtTokenContract;
        investors = _investors;
        EMILeft = _time;
    }

    modifier onlyBorrower() {
        require(msg.sender == borrower, "only borrower can call this function");
        _;
    }

    function calcEMI() public view returns (uint) {
        //@dev note that time is in months and calculation is done via simple interest
        uint EMI = (principal + (principal * interestRate * time) / 1200) / 12;
        return EMI;
    }

    // @dev note that transfer function is build to support ETH currently
    function transferFunds() public payable returns (bool) {
        // use output of calculateEMI
        require(msg.value == calcEMI(), "EMI AND MSG.VALUE DOES NOT MATCH");
        require(EMILeft > 0, "NO EMI IS LEFT");
        uint EMIToPay;
        if (block.timestamp < nextEpochToPay) {
            EMIToPay = calcEMI();
        } else {
            uint daysElapsed = (block.timestamp - nextEpochToPay) / 86400;
            EMIToPay = calcEMI() + ((daysElapsed * penalty) * calcEMI()) / 100;
        }
        uint totalSupplyDebtToken = getInvestorProposal(debtTokenContract)
            .totalSupply();

        for (uint i = 0; i <= investors.length; i++) {
            uint _tokenBal = getInvestorProposal(debtTokenContract).balanceOf(
                investors[i]
            );
            uint _toPay = (_tokenBal / totalSupplyDebtToken) * EMIToPay;
            (bool sent, ) = investors[i].call{value: _toPay}("");
            require(sent, "Failed to send Ether");
            if (sent) EMILeft -= 1;
        }
        nextEpochToPay += thirtyDayEpoch;
        return true;
    }
}
