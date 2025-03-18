// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Crowdfunding Smart Contract
 * @dev Allows users to create crowdfunding campaigns, contribute funds, withdraw funds if the goal is met,
 * and refund contributors if the goal is not met before the deadline.
 */
contract CrowdFunding{

    uint256 campaignCount = 0;

    struct Campaign {
        address payable creator;
        uint256 goal;
        uint256 deadline;
        uint256 amtRaised;
        mapping(address => uint256) donors;
    }

    mapping(uint256 => Campaign) internal Campaigns;

     /**
     * @notice Creates a new crowdfunding campaign
     * @param goal The funding goal for the campaign (in Wei)
     * @param duration Duration of the campaign in seconds
     */

    function createCampaign(uint256 goal, uint256 duration) external{
        require(goal>0, "goal must be greater than 0");
        require(duration>0, "Duration must be. greater than 0");

        Campaign storage newCampaign = Campaigns[campaignCount];
        newCampaign.creator = payable(msg.sender);
        newCampaign.goal = goal;
        newCampaign.deadline = duration;
        newCampaign.amtRaised = 0;
    }

    /**
     * @notice Allows users to donate to a specific campaign
     * @param campaignID The ID of the campaign to donate to
     */

    function donate(uint256 campaignID) external payable{
        Campaign storage campaign = Campaigns[campaignID]; 
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "Donation must be greater than 0");

        campaign.donors[msg.sender] += msg.value;
        campaign.amtRaised += msg.value;
    }

    /**
     * @notice Allows the creator to withdraw funds if the funding goal is met before the deadline
     * @param campaignID The ID of the campaign to withdraw funds from
    */

    function withdraw(uint256 campaignID) external{
        Campaign storage campaign = Campaigns[campaignID]; 
        require(campaign.creator == msg.sender, "Only the Creator can withdraw");
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(campaign.amtRaised < campaign.goal, "goal is not achieved yet");
        payable(msg.sender).transfer(campaign.amtRaised);
    }

    /**
     * @notice Allows donors to claim a refund if the funding goal is not met before the deadline
     * @param campaignID The ID of the campaign to claim a refund from
     */

    function refund(uint256 campaignID) external{
        Campaign storage campaign = Campaigns[campaignID]; 
        require(block.timestamp > campaign.deadline, "Campaign is Active");
        require(campaign.amtRaised < campaign.goal, "Goal met, no refunds");
        uint256 contribution = campaign.donors[msg.sender];
        payable(msg.sender).transfer(contribution);
    }
}