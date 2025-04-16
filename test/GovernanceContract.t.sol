// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GovernanceContract.sol";
import "../src/TimelockController.sol";

contract GovernorTest is Test {
    Governor public governor;
    MyTimelock public timelock;
    GovToken public token;

    address public admin;
    address public proposer;
    address public voter1;
    address public voter2;

    uint256 public proposalThreshold = 1000 ether;
    uint256 public quorum = 3000 ether;

    function setUp() public {
        admin = address(1);
        proposer = address(2);
        voter1 = address(3);
        voter2 = address(4);

        //deploying both the contracts
        token = new GovToken("Governance Token", "GT");
        timelock = new MyTimelock(address(this), 2 days);//this test contract is the temporary admin

        governor = new Governor(
            address(timelock),
            address(token),
            proposalThreshold,
            quorum
        );

        vm.prank(address(timelock));
        timelock.setPendingAdmin(address(governor));
        vm.prank(address(governor));
        timelock.acceptAdmin();//now governor is the admin

        token.mint(proposer, 5000 * 10 ** 18);
        token.mint(voter1, 2000 * 10 ** 18);
        token.mint(voter2, 2000 * 10 ** 18);

        vm.prank(proposer);
        token.delegate(proposer);

        vm.prank(voter1);
        token.delegate(voter1);

        vm.prank(voter2);
        token.delegate(voter2);

        vm.roll(block.number + 1);
    }

    function testProposal() public {
        // Ensure the proposer has enough votes before creating the proposal
        uint256 proposerVotesBefore = token.getVotes(proposer);
        console.log("Proposer votes before proposal: ", proposerVotesBefore);
        console.log("Proposal threshold: ", proposalThreshold);

        // Ensure the proposer has enough votes to propose
        require(proposerVotesBefore >= proposalThreshold, "Proposer does not have enough votes");

        string memory signature = "setVotingPower(uint256)";
        bytes memory data = abi.encode(100);

        vm.roll(block.number + 1);//voting dalay 1 block baad voting start hogi
        vm.prank(proposer);
        governor.propose(address(governor), signature, data);

        Governor.Proposal memory proposal = governor.getProposal(0);

        assertEq(proposal.proposer, proposer, "Proposal proposer mismatch");
        assertEq(proposal.target, address(governor), "Proposal target mismatch");
        assertEq(proposal.signature, signature, "Proposal signature mismatch");
        assertEq(proposal.data, data, "Proposal data mismatch");
    }

    function testVote() public {
        string memory signature = "setVotingPower(uint256)";
        bytes memory data = abi.encode(100);

        vm.prank(proposer);
        governor.propose(address(governor), signature, data);

        vm.roll(block.number + 1);

        vm.prank(voter1);
        governor.vote(0, true);

        Governor.Proposal memory proposal = governor.getProposal(0);
        assertEq(proposal.votesFor, 2000 ether);
        assertTrue(governor.hasVoted(voter1, 0));
    }

    function testQueueProposal() public {
        string memory signature = "setVotingPower(uint256)";
        bytes memory data = abi.encode(100);

        vm.prank(proposer);
        governor.propose(address(governor), signature, data);

        vm.roll(block.number + 1);
        vm.prank(voter1);
        governor.vote(0, true);
        vm.prank(voter2);
        governor.vote(0, true);

        vm.roll(block.number + 7);

        vm.prank(address(governor));
        governor.queue(0);

        Governor.Proposal memory proposal = governor.getProposal(0);
        assertTrue(proposal.queued);
    }

    function testExecuteProposal() public {
        string memory signature = "setVotingPower(uint256)";
        bytes memory data = abi.encode(100);

        vm.prank(proposer);
        governor.propose(address(governor), signature, data);

        vm.roll(block.number + 1); // voting starts
        vm.prank(voter1);
        governor.vote(0, true);
        vm.prank(voter2);
        governor.vote(0, true);

        vm.roll(block.number + 7); // voting ends — simulate block advancement

        vm.prank(admin);
        governor.queue(0);

        vm.warp(block.timestamp + 2 days + 1); // simulate time after timelock delay

        vm.prank(admin);
        governor.execute(0);

        Governor.Proposal memory proposal = governor.getProposal(0);
        assertTrue(proposal.executed);
    }
}