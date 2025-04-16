// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./GovernorToken.sol"; 
import "./TimelockController.sol"; 

contract Governor  {
    struct Proposal {
        address proposer;
        address target;
        string signature;
        bytes data;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startBlock;
        uint256 endBlock;
        uint256 eta;
        bool executed;
        bool queued;
    }

    Proposal[] public proposals; //storing the proposals in a dynamic array
    mapping(address => mapping(uint256 => bool)) public hasVoted; //user -> proposalId -> hasVoted

    uint256 public proposalThreshold;//minimum number of votes required for a user to submit a proposal
    uint256 public quorum;//minimum number of votes required for a proposal to be considered valid
    uint256 public votingDelay = 1;//The delay (in blocks) between the creation of a proposal and the start of voting
    uint256 public votingPeriod = 5;//number of blocks the voting period lasts
    uint256 public votingPower;//dummy for testing 

    MyTimelock public timelock;
    GovToken public token;

    event ProposalCreated(uint256 proposalId, address proposer, address target, string signature, bytes data);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalQueued(uint256 proposalId, uint256 eta);
    event ProposalExecuted(uint256 proposalId);

    constructor(
        address timelockAddress,
        address govTokenAddress,
        uint256 _proposalThreshold,
        uint256 _quorum
    )
    {
        timelock = MyTimelock(payable(timelockAddress));
        token = GovToken(govTokenAddress);
        proposalThreshold = _proposalThreshold;
        quorum = _quorum;
    }

    function propose(address target, string memory signature, bytes calldata data) external {
        require(token.getVotes(msg.sender) >= proposalThreshold, "Insufficient votes to propose");

        proposals.push(Proposal({
            proposer: msg.sender,
            target: target,//contract address that the proposal will affect
            signature: signature,//function signature in the target contrac
            data: data,//data to be passed to the function call
            votesFor: 0,
            votesAgainst: 0,
            startBlock: block.number + votingDelay,
            endBlock: block.number + votingDelay + votingPeriod,
            eta: 0,//timestamp that proposal will be ready for execution
            executed: false,
            queued: false
        }));

        emit ProposalCreated(proposals.length - 1, msg.sender, target, signature, data);
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId]; 
        require(block.number >= proposal.startBlock, "Voting hasn't started yet");
        require(block.number <= proposal.endBlock, "Voting has ended");
        require(!hasVoted[msg.sender][proposalId], "Already voted");

        uint256 votes = token.getVotes(msg.sender);
        require(votes > 0, "No voting power");

        if (support) {
            proposal.votesFor += votes;
        } else {
            proposal.votesAgainst += votes;
        }

        hasVoted[msg.sender][proposalId] = true;
        emit Voted(proposalId, msg.sender, support);
    }

    function queue(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.number > proposal.endBlock, "Voting still ongoing");
        require(!proposal.queued, "Already queued");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not passed");
        require(proposal.votesFor + proposal.votesAgainst >= quorum, "Quorum not reached");

        uint256 eta = block.timestamp + timelock.delay();//calculating the eta = timestamp when proposal will be ready for the execution
        proposal.eta = eta;//update the ets in the proposal struct
        proposal.queued = true; //mark the proposal as queued

        timelock.queueTransaction( //queue the transaction in the timelock contract
            proposal.target,
            0,
            proposal.signature,
            proposal.data,
            eta
        );

        emit ProposalQueued(proposalId, eta);
    }

    function execute(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.queued, "Not queued");
        require(!proposal.executed, "Already executed");
        require(block.timestamp >= proposal.eta, "Too early to execute");

        timelock.executeTransaction{value: 0}(
            proposal.target,
            0,
            proposal.signature,
            proposal.data,
            proposal.eta
        );

        proposal.executed = true; // mark the proposal as executed
        emit ProposalExecuted(proposalId);
    }

    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }

    //dummy fuction for proposal test
    function setVotingPower(uint256 _power) external {
        votingPower = _power;
    }
}
