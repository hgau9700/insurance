// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Insurance {
    address payable public insurer;

    struct Policy {
        uint256 amount;
        uint256 premium;
        uint256 expiry;
        bool isActive;
    }

    struct Claim {
        uint256 amount;
        uint256 date;
        bool processed;
    }

    mapping(address => Policy) public policies;
    mapping(address => Claim[]) public claims;

    event PolicyCreated(address indexed sender, uint256 amount, uint256 premium, uint256 expiry);
    event ClaimFiled(address indexed sender, uint256 amount, uint256 date);
    event ClaimProcessed(address indexed sender, uint256 amount);

    constructor() {
        insurer = payable(msg.sender);
    }

    function createPolicy(address policyHolder, uint256 amount, uint256 premium, uint256 expiry) external {
        require(msg.sender == insurer, "Only the insurer can create policies.");
        require(policies[policyHolder].isActive == false, "Policy already exists.");
        policies[policyHolder] = Policy(amount, premium, expiry, true);
        emit PolicyCreated(policyHolder, amount, premium, expiry);
    }

    function fileClaim(uint256 amount) external {
        require(policies[msg.sender].isActive == true, "No policy found.");
        require(block.timestamp < policies[msg.sender].expiry, "Policy expired.");
        claims[msg.sender].push(Claim(amount, block.timestamp, false));
        emit ClaimFiled(msg.sender, amount, block.timestamp);
    }

    function processClaim(address policyHolder) external payable {
        require(msg.sender == insurer, "Only the insurer can process claims.");
        require(policies[policyHolder].isActive == true, "Policy does not exist.");
        uint256 claimAmount = 0;
        for (uint256 i = 0; i < claims[policyHolder].length; i++) {
            if (claims[policyHolder][i].processed == false) {
                claimAmount += claims[policyHolder][i].amount;
                claims[policyHolder][i].processed = true;
            }
        }
        require(claimAmount > 0, "No claims to process.");
        require(msg.value >= claimAmount, "Insufficient funds to process claim.");
        (bool sent, ) = policyHolder.call{value: claimAmount}("");
        require(sent, "Failed to send Ether.");
        emit ClaimProcessed(policyHolder, claimAmount);
    }

    function cancelPolicy() external {
        require(policies[msg.sender].isActive == true, "No policy found.");
        policies[msg.sender].isActive = false;
    }

    function withdraw() external {
        require(msg.sender == insurer, "Only the insurer can withdraw funds.");
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether.");
    }
}
