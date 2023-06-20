// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRNG.sol";

contract Vault {
    IERC20 public immutable stableCoin;
    address public immutable owner;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public feeAmounts;
    mapping(address => uint256) public feePercents;
    mapping(address => uint256) public totalWinningsOfUser;
    // mapping(address => uint256) public referralCode;
    // mapping(uint256 => address) private referralCodeToAddress;
    mapping(address => string) public username;
    mapping(string => address) public usernameToAddress;
    mapping(address => bool) public hasUsername;
    mapping(address => address) public referrer;
    mapping(address => uint256) public referralRewards;
    mapping(address => uint256) public referralPoolRewards;
    mapping(address => uint256) public totalReferred;
    mapping(address => address[]) public referredUsers;
    mapping(address => uint256) public overallReferralRewardsOfUser;
    mapping(address => bool) public hasSignedConsent;

    uint256 public referralJackpot = 60000000000;
    uint256 public totalReferralWinners = 60;
    uint256 public specialWalletAmount = 0;
    address[] public feeRecepients;
    uint256 public withdrawFeePercent = 100000;
    address public immutable withdrawFeeWallet;

    address[][] public poolMembers;
    uint256 public totalBatches = 0;
    address[] public currentActiveBatch;
    mapping(uint256 => address[]) public gameToWinningBatch;
    uint256 public gameCount = 0;
    address public RNGManager;
    event ReferralWinnerAnnounced(address[] winners, uint256 gameId);

    constructor(
        IERC20 _stableCoin,
        address[] memory _feeRecepients,
        uint256[] memory _feePercent,
        address _withdrawFeeWallet
    ) {
        require(
            _feeRecepients.length == _feePercent.length,
            "Fee recepients and fee percent size mismatch"
        );
        feeRecepients = _feeRecepients;
        uint256 totalFeePercent = 0;
        for (uint256 i = 0; i < _feePercent.length; i++) {
            feePercents[_feeRecepients[i]] = _feePercent[i];
            totalFeePercent += _feePercent[i];
        }
        require(totalFeePercent == 100000000, "Total fee percent must be 100");
        stableCoin = _stableCoin;
        withdrawFeeWallet = _withdrawFeeWallet;
        owner = msg.sender;
        gameCount++;
        currentActiveBatch = new address[](0);
        for(uint256 i=0;i<totalReferralWinners;i++){
            currentActiveBatch.push(address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, i))))));
        }
        totalBatches++;
        poolMembers.push(currentActiveBatch);
        currentActiveBatch = new address[](0);
    }

    function addWhiteListed(address[] calldata _address) external {
        require(msg.sender == owner, "Only owner can add whitelisted");
        for (uint256 i = 0; i < _address.length; i++) {
            isWhitelisted[_address[i]] = true;
        }
    }

    function removeWhiteListed(address[] calldata _address) external {
        require(msg.sender == owner, "Only owner can add whitelisted");
        for (uint256 i = 0; i < _address.length; i++) {
            isWhitelisted[_address[i]] = false;
        }
    }

    function distributePoolPrize(
        address _winner1,
        address _winner2,
        address _winner3,
        uint256[] calldata _amount,
        uint256 jackpot
    ) public {
        require(isWhitelisted[msg.sender], "Only whitelisted can add rewards");
        uint256 fees = (jackpot * 10);
        fees = fees / 100;
        for (uint256 i = 0; i < feeRecepients.length; i++) {
            feeAmounts[feeRecepients[i]] +=
                (fees * feePercents[feeRecepients[i]]) /
                (100 * (10**6));
        }
        uint256 _referralPrice = ((jackpot - fees) * 10) / 100;
        rewards[_winner1] += _amount[0];
        rewards[_winner2] += _amount[1];
        rewards[_winner3] += _amount[2];
        totalWinningsOfUser[_winner1] += _amount[0];
        totalWinningsOfUser[_winner2] += _amount[1];
        totalWinningsOfUser[_winner3] += _amount[2];
        if (referrer[_winner1] != address(0)) {
            referralRewards[referrer[_winner1]] += _amount[0] / 10;
            overallReferralRewardsOfUser[referrer[_winner1]] += _amount[0] / 10;
        } else {
            specialWalletAmount += _amount[0] / 10;
        }
        if (referrer[_winner2] != address(0)) {
            referralRewards[referrer[_winner2]] += _amount[1] / 10;
            overallReferralRewardsOfUser[referrer[_winner2]] += _amount[1] / 10;
        } else {
            specialWalletAmount += _amount[1] / 10;
        }
        if (referrer[_winner3] != address(0)) {
            referralRewards[referrer[_winner3]] += _amount[2] / 10;
            overallReferralRewardsOfUser[referrer[_winner3]] += _amount[1] / 10;
        } else {
            specialWalletAmount += _amount[2] / 10;
        }
        specialWalletAmount += (_referralPrice * 10) / 100;
    }

    function addMemberToPool(address _address, string calldata _referralCode) public {
        require(isWhitelisted[msg.sender], "Unsupported Contract");
        require(referrer[_address] == address(0), "Referrer already set");
        require(
            usernameToAddress[_referralCode] != address(0),
            "Invalid referral code"
        );
        require(
            !hasUsername[_address],
            "User's referral code already set"
        );
        referrer[_address] = usernameToAddress[_referralCode];
        totalReferred[usernameToAddress[_referralCode]] += 1;
        referredUsers[usernameToAddress[_referralCode]].push(_address);

        currentActiveBatch.push(_address);
        if (currentActiveBatch.length == totalReferralWinners) {
            totalBatches++;
            poolMembers.push(currentActiveBatch);
            currentActiveBatch = new address[](0);
        }
        if (totalBatches >= 1 && specialWalletAmount >= referralJackpot) {
            IRNG(payable(RNGManager)).requestRandomNumber(gameCount, address(this), 1);
            gameCount++;
        }
    }

    function setUsername(address _address, string calldata _username) public {
        require(isWhitelisted[msg.sender], "Only for whitelisted contracts");
        require(!hasUsername[_address], "Username already set");
        username[_address] = _username;
        usernameToAddress[_username] = _address;
        hasUsername[_address] = true;
    }

    function verifyUser(address _user) public {
        require(isWhitelisted[msg.sender], "Unsupported Contract");
        hasSignedConsent[_user] = true;
    }

    function decalreReferralWinners(
        uint256 gameId,
        uint256[] memory _randomWords
    ) public {
        require(msg.sender == RNGManager, "Only RNG Manager can declare winners");
        uint256 randomNumber = _randomWords[0] % totalBatches;
        for(uint256 i=0; i< poolMembers[randomNumber].length;i++){
            referralPoolRewards[poolMembers[randomNumber][i]] += referralJackpot / totalReferralWinners;
            poolMembers[randomNumber][i] = poolMembers[poolMembers.length - 1][i];
        }
        emit ReferralWinnerAnnounced(poolMembers[poolMembers.length - 1], gameId);
        poolMembers.pop();
        totalBatches--;
    }

    function getAllReferredUser(address _address)
        external
        view
        returns (address[] memory)
    {
        return referredUsers[_address];
    }

    function withdrawRewards() external {
        uint256 amount = rewards[msg.sender];
        uint256 fees = (amount * withdrawFeePercent) / (100 * 10**6);
        feeAmounts[withdrawFeeWallet] += fees;
        amount -= fees;
        rewards[msg.sender] = 0;
        SafeERC20.safeTransfer(stableCoin, msg.sender, amount);
    }

    function withdrawReferralRewards() external {
        uint256 amount = referralRewards[msg.sender];
        uint256 fees = (amount * withdrawFeePercent) / (100 * 10**6);
        feeAmounts[withdrawFeeWallet] += fees;
        amount -= fees;
        referralRewards[msg.sender] = 0;
        SafeERC20.safeTransfer(stableCoin, msg.sender, amount);
    }

    function withdrawReferralPoolRewards() external {
        uint256 amount = referralPoolRewards[msg.sender];
        uint256 fees = (amount * withdrawFeePercent) / (100 * 10**6);
        feeAmounts[withdrawFeeWallet] += fees;
        amount -= fees;
        referralPoolRewards[msg.sender] = 0;
        SafeERC20.safeTransfer(stableCoin, msg.sender, amount);
    }

    function withdrawFees() external {
        uint256 amount = feeAmounts[msg.sender];
        feeAmounts[msg.sender] = 0;
        SafeERC20.safeTransfer(stableCoin, msg.sender, amount);
    }

    function setRNGManager(address _rngManager) external {
        require(msg.sender == owner, "Only owner can set RNG Manager");
        RNGManager = _rngManager;
    }

    function testEvent() public {
        address[] memory _address = new address[](totalReferralWinners);
        for (uint256 i = 0; i < totalReferralWinners; i++) {
            _address[i] = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, i)))));
        }
        emit ReferralWinnerAnnounced(_address, 0);
    }

    receive() external payable {
    }
}