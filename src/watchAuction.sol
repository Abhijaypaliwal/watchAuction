pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {Test, console} from "forge-std/Test.sol";

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
        if (block.timestamp < nextEpochToPay) 
        {
            EMIToPay = calcEMI();
        }
        else {
            uint daysElapsed = (block.timestamp - nextEpochToPay) / 86400 ; 
            
        }
        uint totalSupplyDebtToken = getInvestorProposal(debtTokenContract).totalSupply();

        for (uint i = 0; i <= investors.length; i++) {
            uint _tokenBal = getInvestorProposal(debtTokenContract).balanceOf(
                investors[i]
            );
            (bool sent, ) = investors[i].call{value: _tokenBal}("");
            require(sent, "Failed to send Ether");
            if (sent) EMILeft -=1;

        }
        return true;
        
    }
}

contract getInvestorProposal is ERC20, Test {
    struct itemDetails {
        string itemName;
        uint256 itemPrice;
        uint256 askingPrice;
        bool isApproved;
        bool onAuction;
        address borrower;
        uint256 auctionDuration;
    }
    itemDetails public details;
    uint256 public _remainingAmount;

    constructor(
        string memory _itemName,
        uint256 _itemPrice,
        uint256 _askingPrice,
        bool _isApproved,
        bool onAuction,
        address _borrower,
        uint256 _auctionDuration
    ) ERC20("WATCH_AUCTION_DEBT_TOKEN", "WATCH_DEBT") {
        details.itemName = _itemName;
        details.itemPrice = _itemPrice;
        details.askingPrice = _askingPrice;
        details.isApproved = _isApproved;
        details.onAuction = onAuction;
        details.borrower = _borrower;
        _remainingAmount = details.askingPrice;
        details.auctionDuration = _auctionDuration;
    }

    modifier onlyBorrower() {
        require(
            msg.sender == details.borrower,
            "only borrower can call this function"
        );
        _;
    }

    struct proposalDetails {
        uint256 amount;
        uint256 interestRate;
        uint256 duration;
        address investor;
        bool approved;
        bool claimed;
    }
    proposalDetails detailsProposer;

    uint256 public proposalNum;
    mapping(uint256 => proposalDetails) public proposalMapping;

    function mintToken(address _to, uint256 _amount) internal returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    function getProposals(
        uint256 _interestRate,
        uint256 _duration
    ) external payable {
        require(
            msg.value > 0 &&
                msg.value <= details.askingPrice &&
                _interestRate > 0 &&
                _duration > 0 &&
                block.timestamp < details.auctionDuration,
            "either of the details are incorrect or auction is expired"
        );
        detailsProposer.amount = msg.value;
        detailsProposer.interestRate = _interestRate;
        detailsProposer.duration = _duration;
        detailsProposer.investor = msg.sender;
        detailsProposer.approved = false;
        detailsProposer.claimed = false;
        proposalNum++;
        proposalMapping[proposalNum] = detailsProposer;
    }

    function approveProposal(
        uint256 _proposalNum
    ) external onlyBorrower returns (bool) {
        // require(
        //     _remainingAmount >= proposalMapping[_proposalNum].amount,
        //     "remaining amount is less than proposal"
        // );
        require(_proposalNum <= proposalNum, "proposal number does not exist");
        proposalMapping[_proposalNum].approved = true;

        _remainingAmount -= proposalMapping[_proposalNum].amount;
        return true;
    }

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
}

// Auction watch contract
// Author: Abhijay Paliwal

contract AuctionWatch is ERC721 {
    struct itemDetails {
        string itemName;
        uint256 itemPrice;
        uint256 askingPrice;
        bool isApproved;
        bool onAuction;
        address borrower;
        uint256 auctionDuration;
    }

    address owner;
    itemDetails details;
    uint256 itemNumber;
    mapping(uint256 => itemDetails) public itemNumberToDetails;

    constructor() ERC721("WatchNFT", "WATCH") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner can call this function");
        _;
    }

    function mintNFT(address _to, uint256 _tokenId) internal returns (bool) {
        _safeMint(_to, _tokenId);
        return true;
    }

    function setItemForAuction(
        string memory _itemName,
        uint256 _itemPrice,
        uint256 _askingPrice,
        bool _isApproved,
        address _borrower,
        uint256 _auctionDuration
    ) external onlyOwner returns (address) {
        itemNumber++;
        details.itemName = _itemName;
        details.itemPrice = _itemPrice;
        details.askingPrice = _askingPrice;
        details.isApproved = _isApproved;
        details.onAuction = true;
        details.borrower = _borrower;
        details.auctionDuration = _auctionDuration;
        mintNFT(msg.sender, itemNumber);
        itemNumberToDetails[itemNumber] = details;

        getInvestorProposal getProposal = new getInvestorProposal(
            _itemName,
            _itemPrice,
            _askingPrice,
            _isApproved,
            true,
            _borrower,
            _auctionDuration
        );

        return address(getProposal);
    }
}
