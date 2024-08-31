// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";

contract ERC20StakingContract {
    IERC20 public stakingToken;  // ERC20 token used for staking

    mapping(address => uint256) public stakedAmounts;
    mapping(address => uint256) public stakingStartTime;

    uint256 public constant FULL_PERIOD = 1 minutes;
    uint256 public constant FULL_REWARD_BASIS_POINTS = 2000; // 20% reward
    uint256 public constant PARTIAL_REWARD_BASIS_POINTS = 500; // 5% reward
    uint256 public constant BASIS_POINTS_DIVISOR = 10000; // 100% represented as 10000 basis points

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);

    constructor(IERC20 _stakingToken) {
        stakingToken = _stakingToken;  // Set the ERC20 token to be staked
    }

    // Stake ERC20 tokens in the contract
    function stake(uint256 amount) external {
        require(amount > 0, "You need to stake some tokens.");

        // Transfer tokens from the user's address to the contract
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed.");

        // Add the staked amount to the user's balance and set the staking start time
        stakedAmounts[msg.sender] += amount;
        stakingStartTime[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    // Internal function to calculate rewards based on staking duration
    function calculateReward(address staker) public view returns (uint256) {
        uint256 stakedTime = block.timestamp - stakingStartTime[staker];
        uint256 stakedAmount = stakedAmounts[staker];
        uint256 reward;

        if (stakedTime >= FULL_PERIOD) {
            // Full reward if staked for the full period
            reward = (stakedAmount * FULL_REWARD_BASIS_POINTS) / BASIS_POINTS_DIVISOR;
        } else {
            // Partial reward if staked for less than the full period
            reward = (stakedAmount * PARTIAL_REWARD_BASIS_POINTS) / BASIS_POINTS_DIVISOR;
        }

        return reward;
    }

    // Withdraw staked tokens and earned rewards
    function withdraw() external {
        uint256 stakedAmount = stakedAmounts[msg.sender];
        require(stakedAmount > 0, "No staked amount.");

        // Calculate the reward
        uint256 reward = calculateReward(msg.sender);
        uint256 totalAmount = stakedAmount + reward;

        // Reset the user's staking data
        stakedAmounts[msg.sender] = 0;
        stakingStartTime[msg.sender] = 0;

        // Transfer staked amount and reward to the user
        require(stakingToken.transfer(msg.sender, totalAmount), "Transfer failed.");

        emit Withdrawn(msg.sender, stakedAmount, reward);
    }

    // Returns the staked amount and staking start time for a user
    function getStakingInfo(address user) external view returns (uint256 stakedAmount, uint256 startTime) {
        return (stakedAmounts[user], stakingStartTime[user]);
    }
}
