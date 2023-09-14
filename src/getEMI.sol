//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {getInvestorProposal} from "./getInvestorProposal.sol";
import {Test, console} from "forge-std/Test.sol";

/*
 * @title getEMI
 * @author Abhijay Paliwal
 *
 * The contract is responsible to calculate and receive EMI from borrower
 *
 */

contract getEMI is Test {
    struct proposalDetails {
        uint256 amount;
        uint256 interestRate;
        uint256 duration;
        address investor;
        bool approved;
        bool claimed;
    }

    //proposalDetails details;
    proposalDetails[] public proposalArray;
    // uint principal;
    // uint interestRate;
    // uint time;
     address borrower;
    // address[] investors;
    address debtTokenContract;
    uint EMILeft; // months of EMI to be paid
    uint penalty; // penalty paid by borrower for late payment, in % per day
    uint public constant thirtyDayEpoch = 2629743;
    uint public nextEpochToPay = 2629743 + block.timestamp;

    constructor(
        proposalDetails[] storage detailsProposal,
        address _debtTokenAddress, 
        address _borrower
    ) {
        proposalArray = detailsProposal;
        debtTokenContract = _debtTokenAddress;
        borrower = _borrower;
        //console.log(proposalArray[1]);
    }

    // constructor(
    //     uint _principal,
    //     uint _interestRate,
    //     uint _time,
    //     address _borrower,
    //     address[] memory _investors,
    //     address _debtTokenContract
    // ) {
    //     principal = _principal;
    //     interestRate = _interestRate * 1000;
    //     time = _time;
    //     borrower = _borrower;
    //     _debtTokenContract = debtTokenContract;
    //     investors = _investors;
    //     EMILeft = _time;
    // }
function hellow( proposalDetails[] memory detailsProposal,
        address _debtTokenAddress, 
        address _borrower
    ) public {
    {
        proposalArray = detailsProposal;
        debtTokenContract = _debtTokenAddress;
        borrower = _borrower;
    }
}
    modifier onlyBorrower() {
        require(msg.sender == borrower, "only borrower can call this function");
        _;
    }

    function returnEMI(uint principal, uint interestRate, uint time) internal returns (uint) {
        if (block.timestamp < nextEpochToPay) {
            return  calcEMI(principal, interestRate, time);
        } else {
            uint daysElapsed = (block.timestamp - nextEpochToPay) / 86400;
            return calcEMI(principal, interestRate, time) + ((daysElapsed * penalty) * calcEMI(principal, interestRate, time)) / 100;
        }
    }

    function calcEMI(uint principal, uint interestRate, uint time) public view returns (uint) {
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

        uint totalSupplyDebtToken = getInvestorProposal(debtTokenContract)
            .totalSupply();

        for (uint i = 0; i <= proposalArray.length; i++) {
            uint _tokenBal = getInvestorProposal(debtTokenContract).balanceOf(
                proposalArray[i].investor
            );
            uint _toPay = (_tokenBal / totalSupplyDebtToken) * EMIToPay;
            (bool sent, ) = proposalArray[i].investor.call{value: _toPay}("");
            require(sent, "Failed to send Ether");
            if (sent) EMILeft -= 1;
        }
        nextEpochToPay += thirtyDayEpoch;
        return true;
    }
}
