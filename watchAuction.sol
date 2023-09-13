pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract getInvestorProposal{
     struct itemDetails {
        string itemName;
        uint256 itemPrice;
        uint256 askingPrice;
        bool isApproved;
        bool onAuction;
        address borrower;
    }
    itemDetails public details;
    constructor( itemDetails memory getDetails) {
        details = getDetails;
    }

    modifier onlyBorrower() {
        require(msg.sender == details.borrower, "only borrower can call this function");
        _;
    }

    struct proposalDetails {
        uint amount;
        uint interestRate;
        uint duration;
        address investor;
    }
    proposalDetails detailsProposer;

    uint proposalNum;
    mapping(uint => proposalDetails) public proposalMapping;


    function getProposals(uint _interestRate, uint _duration) external payable{
        require(msg.value > 0 && _interestRate > 0 && _duration > 0, "either of the details are incorrect");
        detailsProposer.amount = msg.value;
        detailsProposer.interestRate = _interestRate;
        detailsProposer.duration = _duration;
        detailsProposer.investor = msg.sender;
    } 

    function 


}
contract AuctionWatch is ERC721 {
    struct itemDetails {
        string itemName;
        uint256 itemPrice;
        uint256 askingPrice;
        bool isApproved;
        bool onAuction;
        address borrower;
    }

    address owner;
    itemDetails details;
    uint itemNumber;
    mapping(uint => itemDetails) public itemNumberToDetails;

    constructor() ERC721("WatchNFT", "WATCH"){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner can call this function");
        _;
    }

    function mintNFT(address _to, uint _tokenId) internal returns(bool) {
        _safeMint(_to, _tokenId);
        return true;
    }

    function setItemForAuction(
        string memory _itemName,
        uint256 _itemPrice,
        uint256 _askingPrice,
        bool _isApproved,
        address _borrower
    ) external onlyOwner returns (bool) {
        itemNumber++;
        details.itemName = _itemName;
        details.itemPrice = _itemPrice;
        details.askingPrice = _askingPrice;
        details.isApproved = _isApproved;
        details.onAuction = true;
        details.borrower = _borrower;
        mintNFT(msg.sender, itemNumber);
        itemNumberToDetails[itemNumber] = details; 
    }
}
