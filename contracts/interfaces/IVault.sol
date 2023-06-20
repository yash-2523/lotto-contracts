// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IVault {
    event ReferralWinnerAnnounced(address[] winners, uint256 gameId);

    function RNGManager() external view returns (address);

    function addMemberToPool(
        address _address,
        string memory _referralCode
    ) external;

    function addWhiteListed(address[] memory _address) external;

    function currentActiveBatch(uint256) external view returns (address);

    function decalreReferralWinners(
        uint256 gameId,
        uint256[] memory _randomWords
    ) external;

    function distributePoolPrize(
        address _winner1,
        address _winner2,
        address _winner3,
        uint256[] memory _amount,
        uint256 jackpot
    ) external;

    function feeAmounts(address) external view returns (uint256);

    function feePercents(address) external view returns (uint256);

    function feeRecepients(uint256) external view returns (address);

    function gameCount() external view returns (uint256);

    function gameToWinningBatch(
        uint256,
        uint256
    ) external view returns (address);

    function getAllReferredUser(
        address _address
    ) external view returns (address[] memory);

    function hasSignedConsent(address) external view returns (bool);

    function hasUsername(address) external view returns (bool);

    function isWhitelisted(address) external view returns (bool);

    function overallReferralRewardsOfUser(
        address
    ) external view returns (uint256);

    function owner() external view returns (address);

    function poolMembers(uint256, uint256) external view returns (address);

    function referralJackpot() external view returns (uint256);

    function referralPoolRewards(address) external view returns (uint256);

    function referralRewards(address) external view returns (uint256);

    function referredUsers(address, uint256) external view returns (address);

    function referrer(address) external view returns (address);

    function removeWhiteListed(address[] memory _address) external;

    function rewards(address) external view returns (uint256);

    function setRNGManager(address _rngManager) external;

    function setUsername(address _address, string memory _username) external;

    function specialWalletAmount() external view returns (uint256);

    function stableCoin() external view returns (address);

    function testEvent() external;

    function totalBatches() external view returns (uint256);

    function totalReferralWinners() external view returns (uint256);

    function totalReferred(address) external view returns (uint256);

    function totalWinningsOfUser(address) external view returns (uint256);

    function username(address) external view returns (string memory);

    function usernameToAddress(string memory) external view returns (address);

    function verifyUser(address _user) external;

    function withdrawFeePercent() external view returns (uint256);

    function withdrawFeeWallet() external view returns (address);

    function withdrawFees() external;

    function withdrawReferralPoolRewards() external;

    function withdrawReferralRewards() external;

    function withdrawRewards() external;

    receive() external payable;
}
