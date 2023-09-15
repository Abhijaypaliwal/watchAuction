//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Test, console} from "forge-std/Test.sol";


// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#::
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&            @@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&  .B########@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@A@H@J@Y@@A@I@A@@@@@@@@@@@@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@B@I@A@@P@L@W@L@@@@@@@@@@@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@@&&&&&&&&&&&&@@@&  .@@@@@@@@@@@@#::~&&&&&&&&&
// @@@@@@@@@@@@@@@&.           G@@&  .@@@@@@@@@@@@#:::
// @@@@@@@@@@@@@@@&   PBBBBB.  G@@&  .@@@@@@@@@@@@#::~&&&&&&&&&
// @@@@@@@@@@@@@@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// @@@@@@@@@@@@@@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// &&&&&&&&&&&&@@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// ....        P@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// ...P#####~  P@@&.  G#BBBB:  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// ...&@@@@@7  P@@&.           G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// ...&@@@@@7  P@@&.  B&&&&&:  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// ...&@@@@@7  P@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// ...&@@@@@7  P@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// ...J55555:  P@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// ......   ...G@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// ...#@@B  ^@@@@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// ...&@@@^  #@@@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// ...&@@@P  !@@@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#::!@@@@@@@@@
// ...&@@@@:  &@@@&. .@@@@@@^  G@@&  .@@@@@@@@@@@@#:: @@@@@@@@@
// ...&@@@@5  ?@@@&. .@@@@@@^  G@@&  .         @@@@
// ...&@@@@&. .@@@&. .@@@@@@^  G@@&@@@@@@@@@#@@@@@@@@@@@@@@@@@@
/**
 * @title getInvestorProposal
 * @author Abhijay Paliwal
 *
 * The contract is designed to get proposals by investors at specified period of time
 *
 * The investors can propose their proposals in ETH with parameters of interest rate
 * and time period(for months)
 *
 * After proposal, the ETH amount of investor would be blocked for certain amount of time
 * which is after when borrower approves proposal or remainingAmount becomes zero and auction ends
 *
 * If borrower accepts the proposal, the ETH amount would not be claimed by investor, and borrower would claim
 * the ETH after remainingAmount becomes zero
 *
 * If proposal is not accepted, investor can claim ETH from contract after emainingAmount becomes zero and auction ends
 *
 * The investor would recieve ERC20 Tokens when their proposal is accepted, these tokens would be used to take EMI from borrower
 *
 * @notice there is no role of admin here, the scope lies between borrower and investors
 * @notice the debt token equals to wei, i.e. 1 debt token = 1 wei
 */

interface watchAuction {
    function setAuctionOff(uint _itemNumber) external returns (bool);
}

contract getInvestorProposal is ERC20, Test { 
    uint256 public _remainingAmount;
    uint EMIsPaid; // months of EMI borrower had paid
    uint penalty = 1; // penalty paid by borrower for late payment, in % per day
    uint public constant thirtyDayEpoch = 2629743; //number of seconds in thirty days
    uint public nextEpochToPay; // next timestamp to pay for borrower
    bool public setForEMI;
    uint256 public proposalNum;
    //address public watchAuctionContract;
    
    struct itemDetails {
        uint itemNumber;
        string itemName;
        uint256 itemPrice;
        uint256 askingPrice;
        uint256 borrowDuration;
        bool isApproved;
        bool onAuction;
        address borrower;
        uint256 auctionDuration;
        //address watchAuctionContract;
    }

    struct proposalDetails {
        uint256 amount;
        uint256 interestRate;
        address investor;
        bool approved;
        bool claimed;
    }

    modifier onlyBorrower() {
        require(
            msg.sender == details.borrower,
            "only borrower can call this function"
        );
        _;
    }

    itemDetails public details;
    proposalDetails detailsProposer;
    //watchAuction auctionContract = watchAuction(details.watchAuctionContract);
    mapping(uint256 => uint256) public EMIPaidTimestamps;
    mapping(uint256 => proposalDetails) public proposalMapping;
    proposalDetails[] public acceptedProposalArray;

    ////////////////////
    // Functions //
    ////////////////////

    constructor(
        uint _itemNumber,
        string memory _itemName,
        uint256 _itemPrice,
        uint256 _askingPrice,
        uint256 _borrowDuration,
        bool _isApproved,
        bool onAuction,
        address _borrower,
        uint256 _auctionDuration
       // address _watchAuctionContract
    ) ERC20("WATCH_AUCTION_DEBT_TOKEN", "WATCH_DEBT") {
        details.itemNumber = _itemNumber;
        details.itemName = _itemName;
        details.itemPrice = _itemPrice;
        details.askingPrice = _askingPrice;
        details.isApproved = _isApproved;
        details.onAuction = onAuction;
        details.borrower = _borrower;
        details.borrowDuration = _borrowDuration;
        //details.watchAuctionContract = _watchAuctionContract;
        EMIsPaid = 0;
        _remainingAmount = details.askingPrice;
        details.auctionDuration = _auctionDuration;
        //watchAuctionContract = _watchAuctionContract;
    }

    /*
     * @param: _to: the investor's address to mint debt token
     * @param _amount: number of tokens to mint
     */

    function mintToken(address _to, uint256 _amount) internal returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    /*
     * @param _interestRate: interest rate payable per year
     */

    ////////////////////////////
    // External Functions //
    ////////////////////////////

    function getProposals(uint256 _interestRate) external payable {
        require(
            msg.value > 0 &&
                msg.value <= details.askingPrice &&
                _interestRate > 0 &&
                block.timestamp < details.auctionDuration,
            "either of the details are incorrect or auction is expired"
        );
        detailsProposer.amount = msg.value;
        detailsProposer.interestRate = _interestRate;
        detailsProposer.investor = msg.sender;
        detailsProposer.approved = false;
        detailsProposer.claimed = false;
        proposalNum++;
        proposalMapping[proposalNum] = detailsProposer;
    }

    /*
     * @param _proposalNum: proposalNUm which is accepted by the borrower
     * @notice the function can only be called by the borrower
     * @notice after proposal is successfully approved, investor of than proposalNum
     * cannot claim the ETH
     */

    function approveProposal(
        uint256 _proposalNum
    ) external onlyBorrower returns (bool) {
        require(
            _remainingAmount >= proposalMapping[_proposalNum].amount,
            "remaining amount is less than proposal"
        );
        require(_proposalNum <= proposalNum, "proposal number does not exist");
        proposalMapping[_proposalNum].approved = true;
        console.log("rem amt", _remainingAmount);
        _remainingAmount -= proposalMapping[_proposalNum].amount;
        acceptedProposalArray.push(proposalMapping[_proposalNum]);
        
        if (_remainingAmount == 0) {
            nextEpochToPay = 2629743 + block.timestamp;
            setForEMI = true;
           // auctionContract.setAuctionOff(details.itemNumber);
        }
        return true;
    }

    // function mintEMIContract() internal returns (address) {
    //     proposalDetails[] memory z;
    //     z = acceptedProposalArray;
    //     getEMI EMIContract = new getEMI();
    //     EMIContract.hellow(z, address(this), details.borrower);
    //     return address(EMIContract);
    // }

    /*
     * @param _proposalNum: proposalNum of investor who is claiming ETH
     * @notice The function can only be called by the investor who has submitted
     * his offer and had got proposalNum
     * @notice The function can only be called when auction gets over and borrower approves
     * amount of proposals which equat to its asking amount (_remainingAmount)
     */

    function withdrawFunds(
        uint256 _proposalNum
    ) external payable returns (bool) {
        require(_proposalNum <= proposalNum, "proposal does not exist");
        require(
            details.auctionDuration < block.timestamp && _remainingAmount == 0,
            "auction is not ended yet or remaining amount is not fulfilled"
        );
        require(
            proposalMapping[_proposalNum].investor == msg.sender,
            "only investor of this proposal can call this function"
        );

        require(
            proposalMapping[_proposalNum].claimed != true,
            "amount of this proposal is claimed"
        );

        require(
            proposalMapping[_proposalNum].approved != true,
            "this proposer is claimed by borrower"
        );

        (bool sent, ) = msg.sender.call{
            value: proposalMapping[_proposalNum].amount
        }("");
        require(sent, "Failed to send Ether");
        proposalMapping[_proposalNum].approved == true;
        return true;
    }

    /*
     * @param _proposalNum: proposalNum of investor which borrower has approved
     * @notice The function can only be called by the borrower
     * @notice borrower can claim ETH after auction is ended and proposal approves
     * amount of proposals which equal to its asking amount (_remainingAmount)
     */

    function borrowerClaimFunds(
        uint256 _proposalNum
    ) external payable onlyBorrower returns (bool) {
        require(_proposalNum <= proposalNum, "proposal does not exist");
        require(
            proposalMapping[_proposalNum].approved == true,
            "proposal is not approved"
        );

        require(
            proposalMapping[_proposalNum].claimed != true,
            "amount of this proposal is claimed"
        );

        require(_remainingAmount == 0, "remaining amount should be zero ");

        (bool sent, ) = msg.sender.call{
            value: proposalMapping[_proposalNum].amount
        }("");
        proposalMapping[_proposalNum].claimed = true;
        return sent;
    }

    /*
     * @param _proposalNum: proposalNum of accepted proposal by borrower
     * @notice The contract allows investor to claim debt token after their propsoal is accepted
     * @notice the contract can be called when auction is ended and proposal approves
     * amount of proposals which equat to its asking amount (_remainingAmount)
     */

    function investorClaimDebtToken(
        uint256 _proposalNum
    ) external returns (bool) {
        require(_proposalNum <= proposalNum, "proposal does not exist");
        require(
            proposalMapping[_proposalNum].approved == true,
            "proposal is not approved"
        );
        require(
            proposalMapping[_proposalNum].investor == msg.sender,
            "caller is not investor if this proposal"
        );

        mintToken(msg.sender, proposalMapping[_proposalNum].amount);
        return true;
    }

    // @dev note that transfer function is build to support ETH currently
    function transferFunds() public payable returns (bool) {
        // use output of calculateEMI
        require(setForEMI == true, "Contract is not set to give EMI Now");
        require(EMIsPaid <= details.borrowDuration, "NO EMI IS LEFT");
        console.log("emipaid", EMIsPaid);
        console.log("msg.value is", msg.value);

        uint totalSupplyDebtToken = totalSupply();

        for (uint i = 0; i < acceptedProposalArray.length; i++) {
            uint _tokenBal = balanceOf(acceptedProposalArray[i].investor);
            uint EMIToPay = returnEMI(
                acceptedProposalArray[i].amount,
                acceptedProposalArray[i].interestRate
            );

            //  console.log("investor now is", acceptedProposalArray[i].investor);
            uint _toPay = (_tokenBal * EMIToPay) / totalSupplyDebtToken;

            (bool sent, ) = acceptedProposalArray[i].investor.call{
                value: _toPay
            }("");
            require(sent, "Failed to send Ether");
        }
        EMIsPaid += 1;
        nextEpochToPay += thirtyDayEpoch;
        EMIPaidTimestamps[EMIsPaid] = block.timestamp;
        return true;
    }

    /*
     * @param principal: principal amount given by the investor to borrower
     * @param interestRate: interestRate proided by the investor
     * @notice The function returns EMI of next installment
     * - For example if you want to pay EMI on time, i.e.  inside 30 days + 5 days of cushion
     *   your EMI would be of 30 days and no penalty
     * - If you want to pay EMI late, you have to pay penalty on EMI, which is calculated per day elapsed
     */

    function returnEMI(
        uint principal,
        uint interestRate
    ) public view returns (uint) {
        if (block.timestamp < nextEpochToPay + 5 days) {
            return calcEMI(principal, interestRate);
        } else {
            uint daysElapsed = (block.timestamp - (nextEpochToPay + 5 days)) /
                86400;
            console.log(daysElapsed);

            console.log(
                "hello",
                (((daysElapsed * penalty) * calcEMI(principal, interestRate)) /
                    100)
            );
            return
                calcEMI(principal, interestRate) +
                (((daysElapsed * penalty) * calcEMI(principal, interestRate)) /
                    100);
        }
    }

    /*
     * @notice the function provides timestamps of next EMI to be paid by borrower
     * @output nextEpochToPay: it is 30 days
     * @output nextEpochToPay + 5 days is the cusion of which user has to finally pay EMI
     * else penalty would be imposed
     */

    function nextEMITimestampToBePaid() public view returns (uint, uint) {
        return (nextEpochToPay, nextEpochToPay + 5 days);
    }

    ////////////////////////////
    // Internal Functions //
    ////////////////////////////

    /*
     * @param principal: principal amount of the borrowing funds
     * @param interestRate: interest rate in % offered by investor
     * @param time: Time of EMI in months

    */
    function calcEMI(
        uint principal,
        uint interestRate
    ) internal view returns (uint) {
        //@dev note that time is in months and calculation is done via simple interest
        uint EMI = ((principal +
            (principal * interestRate * details.borrowDuration) /
            1200) / 12) * 2;

        return EMI;
    }
}
