// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakingContract {
    mapping(address => uint256) public stakedAmounts;
    mapping(address => uint256) public stakingStartTime;

    uint256 public constant FULL_PERIOD = 1 minutes;
    uint256 public constant FULL_REWARD_BASIS_POINTS = 2000; // 20% reward
    uint256 public constant PARTIAL_REWARD_BASIS_POINTS = 500; // 5% reward
    uint256 public constant BASIS_POINTS_DIVISOR = 10000; // 100% represented as 10000 basis points

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);



    // Stake Ether in the contract
    function stake() external payable {
        require(msg.value > 0, "You need to stake some Ether.");

        // Add the staked amount to the user's balance
        stakedAmounts[msg.sender] += msg.value;
        stakingStartTime[msg.sender] = block.timestamp;

        emit Staked(msg.sender, msg.value);
    }

    // Internal function to calculate rewards
    function calculateReward(address staker) internal view returns (uint256) {
        uint256 stakedTime = block.timestamp - stakingStartTime[staker];
        uint256 stakedAmount = stakedAmounts[staker];
        uint256 reward;

        if (stakedTime >= FULL_PERIOD) {
            reward = (stakedAmount * FULL_REWARD_BASIS_POINTS) / BASIS_POINTS_DIVISOR;
        } else {
            reward = (stakedAmount * PARTIAL_REWARD_BASIS_POINTS) / BASIS_POINTS_DIVISOR;
        }

        return reward;
    }

    // Withdraw staked Ether and earned rewards
    function withdraw() external  {
        require(stakedAmounts[msg.sender] > 0, "No staked amount.");

        uint256 stakedAmount = stakedAmounts[msg.sender];
        uint256 reward = calculateReward(msg.sender); // Calculate reward
        uint256 totalAmount = stakedAmount + reward; // Total amount to be withdrawn

        // Reset user data before transfer
        stakedAmounts[msg.sender] = 0;
        stakingStartTime[msg.sender] = 0;

        // Transfer staked amount and reward to the user
        (bool success, ) = msg.sender.call{value: totalAmount}("");
        require(success, "Transfer failed.");

        emit Withdrawn(msg.sender, stakedAmount, reward);
    }

    // Returns the contract's Ether balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Returns the staked amount and staking start time for a user
    function getStakingInfo(address user) external view returns (uint256 stakedAmount, uint256 startTime) {
        return (stakedAmounts[user], stakingStartTime[user]);
    }
}
