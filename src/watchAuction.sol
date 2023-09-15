//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {getInvestorProposal} from "./getInvestorProposal.sol";
import {Test, console} from "forge-std/Test.sol";


// ██████╗  █████╗  ██████╗███████╗
// ██╔══██╗██╔══██╗██╔════╝██╔════╝
// ██████╔╝███████║██║     █████╗  
// ██╔══██╗██╔══██║██║     ██╔══╝  
// ██║  ██║██║  ██║╚██████╗███████╗
// ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝
                                
/**
 * @title AuctionWatch
 * @author Abhijay Paliwal
 * The contract is designed for auction of item on the platform
 *
 * The DIC would provide details of item after all due-diligence by proposer and custodian
 *
 * The contract would serve as an gateway to mint auction contract where investors would place
 * their proposals
 *
 * Function would mint ERC-721 NFT of the item to the borrower when function setItemForAuction is called
 * @notice the contract has only one function and can only be called by admin (DIC)
 */

contract AuctionWatch is ERC721 {
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
       // address investorProposalContract;
    }

    //////////////////
    //State Variable //
    /////////////////

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

    ////////////////////
    // Functions //
    ////////////////////

    function mintNFT(address _to, uint256 _tokenId) internal returns (bool) {
        _safeMint(_to, _tokenId);
        return true;
    }

    /*
     * @param _itemname: Name of the item
     * @param _itemPrice: price of item on market (decided by DIC)
     * @param _askingPrice: asking price of item by borrower (decided by DIC)
     * @param _isApproved: boolean for approval by the DIC for item
     * @param _borrower: EOA address of the borrower
     * @param _auctionDuration: duration of auction
     * @notice The function would mint smart contract getInvestorProposal which would be unique for every item
     * @notice The function would mint ERC721 NFT to the borrower
     * @notice function can only be called by the owner
     * @returns THe contract address of the getInvestorProposal contract
     */

    function setItemForAuction(
        string memory _itemName,
        uint256 _itemPrice,
        uint256 _askingPrice,
        uint256 _borrowDuration,
        bool _isApproved,
        address _borrower,
        uint256 _auctionDuration
    ) external onlyOwner returns (address) {
        itemNumber++;
        details.itemNumber = itemNumber;
        details.itemName = _itemName;
        details.itemPrice = _itemPrice;
        details.askingPrice = _askingPrice;
        details.isApproved = _isApproved;
        details.onAuction = true;
        details.borrower = _borrower;
        details.borrowDuration = _borrowDuration;
        details.auctionDuration = _auctionDuration;
        mintNFT(msg.sender, itemNumber);

        getInvestorProposal getProposal = new getInvestorProposal(
            itemNumber,
            _itemName,
            _itemPrice,
            _askingPrice,
            _borrowDuration,
            _isApproved,
            true,
            _borrower,
            _auctionDuration
        );
       // details.investorProposalContract = address(getProposal);
        itemNumberToDetails[itemNumber] = details;

        return address(getProposal);
    }

    // function setAuctionOff(uint _itemNumber) external returns (bool) {
    //     require(
    //         msg.sender ==
    //             itemNumberToDetails[_itemNumber].investorProposalContract,
    //         "not caled by contract having itemnumber given"
    //     );
    //     itemNumberToDetails[_itemNumber].onAuction = false;
    //     return true;
    // }
}
