pragma solidity ^0.8.16;

import {Test, console} from "forge-std/Test.sol";
import "../src/watchAuction.sol";

contract auctionTest is Test {
    AuctionWatch auctionContract;

    function setUp() external {
        vm.prank(address(1));
        auctionContract = new AuctionWatch();
    }

    function testAuction() external {
        vm.startPrank(address(1));
        address getInvestorProposalAddr = auctionContract.setItemForAuction(
            "Rolex Watch",
            10000000000000000,
            10000000000000000,
            true,
            address(1),
            1694601478
        );

        console.log(getInvestorProposalAddr);
        vm.warp(1694601477);
        vm.deal(address(1), 100 ether);
        getInvestorProposal(payable(getInvestorProposalAddr)).getProposals{
            value: 10000000000000000
        }(6, 6);
        vm.stopPrank();
        vm.deal(address(2), 100 ether);
        vm.prank(address(2));
        getInvestorProposal(payable(getInvestorProposalAddr)).getProposals{
            value: 10000000000000000
        }(4, 6);
        vm.deal(address(3), 100 ether);
        vm.prank(address(3));
        getInvestorProposal(payable(getInvestorProposalAddr)).getProposals{
            value: 10000000000000000
        }(4, 12);

        vm.warp(1694601479);
        vm.prank(address(1));
        getInvestorProposal(getInvestorProposalAddr).approveProposal(3);
        vm.prank(address(1));
        getInvestorProposal(getInvestorProposalAddr).borrowerClaimFunds(3);
        vm.prank(address(2));
        getInvestorProposal(getInvestorProposalAddr).withdrawFunds(2);
        vm.prank(address(3));
        getInvestorProposal(getInvestorProposalAddr).investorClaimDebtToken(3);
    }
}
