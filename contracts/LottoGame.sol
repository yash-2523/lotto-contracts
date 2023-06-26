// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IRNG.sol";
import "./interfaces/IEventContract.sol";

contract LottoGame {
    struct Ticket {
        uint256 num1;
        uint256 num2;
        uint256 num3;
        uint256 num4;
        uint256 num5;
        uint256 joker;
    }

    enum Status {
        Open,
        Closed
    }

    struct Game {
        uint256 id;
        uint256 startTime;
        uint256 membersFilled;
        Status status;
    }

    event TicketBought(address buyer, uint256 gameId, uint256[] ticketId);
    event WinnerAnnounced(address winner1, address winner2, address winner3, uint256 gameId, uint256[] rewards);

    address public immutable owner;

    uint256 public immutable poolCapacity = 100;
    uint256 public immutable ticketPrice;
    uint256 public immutable jackpot;
    uint256 public immutable points;
    uint256 public gameCount = 0;
    uint256 ticketCount = 0;
    Game[] public games;
    
    IERC20 public immutable stableCoin;
    IVault public vault;
    mapping(uint256 => Ticket) public tickets;
    mapping(uint256 => mapping(address => uint256)) public numberOfTicketsOfUser;
    mapping(address => uint256[]) public userParticipatedGames;
    mapping(address => uint256) public userGeneratedRewardForReferrer;
    mapping(address => uint256) public userPoints;
    bytes32 public hashedMessage = 0x98c182dcef4c6b953bbd06b92baf2f3e237ce3a883546fdd933dadd12051d56b;
    address[][] public gameMembers;
    uint256[][] public winners;
    uint256[][] public gameTickets;
    mapping(uint256 => uint256) gameSpots;

    uint256[] public winningAmounts;
    uint256[6] maxNumbers = [49, 49, 49, 49, 49, 4];
    uint256 public startTime = 0; // start time of the upcomming game

    address public RNGManager;
    address public eventContract;

    constructor(address _stableCoin, uint256 _ticketPrice, address _vaultAddress, uint256 _points) {    
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        vault = IVault(payable(_vaultAddress));
        jackpot = ticketPrice * poolCapacity;
        points = _points;
        games.push(Game(0, block.timestamp, 0, Status.Open));
        gameMembers.push(new address[](poolCapacity));
        winners.push(new uint256[](3));
        gameTickets.push(new uint256[](poolCapacity));
        gameCount++;
        stableCoin = IERC20(_stableCoin);
        for(uint256 i=1;i<poolCapacity;i++){
            gameSpots[i] = i;
        }
        winningAmounts.push((jackpot * 90 * 40) / 10000);
        winningAmounts.push((jackpot * 90 * 30) / 10000);
        winningAmounts.push((jackpot * 90 * 20) / 10000);
    }

    function buyTickets(string calldata _referrerUsername, string calldata _username, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(block.timestamp >= startTime, "Game not started yet");
        bool hasSignedConsent = IVault(vault).hasSignedConsent(msg.sender);
        if(!hasSignedConsent){
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, hashedMessage));
            address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
            require(signer == msg.sender, "Invalid Messsage");
            IVault(vault).verifyUser(msg.sender);
        }
        Game storage game = games[games.length - 1];
        require(game.status == Status.Open, "Game is closed");
        require(numberOfTicketsOfUser[game.id][msg.sender] < 50, "You can only buy 5 tickets per game");
        if(keccak256(abi.encodePacked(_referrerUsername)) != keccak256(abi.encodePacked("NA"))){
            IVault(vault).addMemberToPool(msg.sender, _referrerUsername);    
        }

        SafeERC20.safeTransferFrom(stableCoin, msg.sender, address(vault), ticketPrice);
        if(!IVault(vault).hasUsername(msg.sender)){
            IVault(vault).setUsername(msg.sender, _username);
        }

        if(game.membersFilled == 0){
            if(game.id != 0){
                if(games[games.length - 2].status == Status.Open){
                    IRNG(payable(RNGManager)).backupRNG(game.id - 1, address(this), 0);
                }
            }
        }

        userPoints[msg.sender] += points;
        if(eventContract != address(0)){
            if(IEventContract(eventContract).startTime() <= block.timestamp && IEventContract(eventContract).endTime() >= block.timestamp){
                IEventContract(eventContract).addPoints(msg.sender, points);
            }
        }
        
        if(userParticipatedGames[msg.sender].length == 0){
            userParticipatedGames[msg.sender].push(game.id);
        }else if(userParticipatedGames[msg.sender][userParticipatedGames[msg.sender].length - 1] != game.id){
            userParticipatedGames[msg.sender].push(game.id);
        }
        // get a random number between 0 and 99 inclusive
        uint256 randomNumber = uint256(keccak256(abi.encode(block.timestamp, msg.sender))) % (poolCapacity - game.membersFilled);

        uint256 _userIndex = gameSpots[randomNumber];
        gameSpots[randomNumber] = gameSpots[poolCapacity - game.membersFilled - 1];
        gameSpots[poolCapacity - game.membersFilled - 1] = _userIndex;
        gameMembers[game.id][_userIndex] = msg.sender;        
        (uint256 num1, uint256 num2, uint256 num3, uint256 num4, uint256 num5, uint256 num6) = getTicket((_userIndex + 1) * (_userIndex + 1));
        ticketCount++;
        tickets[ticketCount] = Ticket(num1, num2, num3, num4, num5, num6);
        gameTickets[game.id][_userIndex] = ticketCount;
        game.membersFilled++;
        numberOfTicketsOfUser[game.id][msg.sender]++;
        if(game.membersFilled == poolCapacity){
            IRNG(payable(RNGManager)).requestRandomNumber(game.id, address(this), 0);
            games.push(Game(gameCount, block.timestamp, 0, Status.Open));
            gameMembers.push(new address[](poolCapacity));
            winners.push(new uint256[](3));
            gameTickets.push(new uint256[](poolCapacity));
            gameCount++;
            startTime = block.timestamp + 119;
        }
        uint256[] memory _tickets = new uint256[](1);
        _tickets[0] = ticketCount;
        emit TicketBought(msg.sender, game.id, _tickets);
    }

    function batchBuyTickets(uint256 _numberOfTickets, string calldata _referrerUsername, string calldata _username, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(block.timestamp >= startTime, "Game not started yet");
        bool hasSignedConsent = IVault(vault).hasSignedConsent(msg.sender);
        if(!hasSignedConsent){
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, hashedMessage));
            address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
            require(signer == msg.sender, "Invalid Messsage");
            IVault(vault).verifyUser(msg.sender);
        }
        Game storage game = games[games.length - 1];
        require(game.status == Status.Open, "Game is closed");
        require(game.membersFilled + _numberOfTickets <= (poolCapacity*90)/100, "Batch buy is allowed till 90% of pool capacity");
        require(numberOfTicketsOfUser[game.id][msg.sender] + _numberOfTickets <= 50, "You can only buy 50 tickets per game");
        if(keccak256(abi.encodePacked(_referrerUsername)) != keccak256(abi.encodePacked("NA"))){
            IVault(vault).addMemberToPool(msg.sender, _referrerUsername);    
        }
        SafeERC20.safeTransferFrom(stableCoin, msg.sender, address(vault), ticketPrice*_numberOfTickets);
        if(!IVault(vault).hasUsername(msg.sender)){
            IVault(vault).setUsername(msg.sender, _username);
        }

        userPoints[msg.sender] += points * _numberOfTickets;
        if(eventContract != address(0)){
            if(IEventContract(eventContract).startTime() <= block.timestamp && IEventContract(eventContract).endTime() >= block.timestamp){
                IEventContract(eventContract).addPoints(msg.sender, points * _numberOfTickets);
            }
        }

        if(userParticipatedGames[msg.sender].length == 0){
            userParticipatedGames[msg.sender].push(game.id);
        }else if(userParticipatedGames[msg.sender][userParticipatedGames[msg.sender].length - 1] != game.id){
            userParticipatedGames[msg.sender].push(game.id);
        }
        uint256[] memory _tickets = new uint256[](_numberOfTickets);
        for(uint256 i=0; i<_numberOfTickets; i++){
            uint256 randomNumber = uint256(keccak256(abi.encode(block.timestamp, msg.sender, i))) % (poolCapacity - game.membersFilled);
            uint256 _userIndex = gameSpots[randomNumber];
            gameSpots[randomNumber] = gameSpots[poolCapacity - game.membersFilled - 1];
            gameSpots[poolCapacity - game.membersFilled - 1] = _userIndex;
            gameMembers[game.id][_userIndex] = msg.sender; 
            (uint256 num1, uint256 num2, uint256 num3, uint256 num4, uint256 num5, uint256 num6) = getTicket((_userIndex + 1) * (_userIndex + 1));
            ticketCount++;
            _tickets[i] = ticketCount;
            tickets[ticketCount] = Ticket(num1, num2, num3, num4, num5, num6);
            gameTickets[game.id][_userIndex] = ticketCount;
            game.membersFilled++;
        }
        
        numberOfTicketsOfUser[game.id][msg.sender]+=_numberOfTickets;
        emit TicketBought(msg.sender, game.id, _tickets);
    }

    function getTicket(uint256 index)
        internal
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        index += uint256(keccak256(abi.encode(block.timestamp, blockhash(block.number - 1), index))) % (1000000000);
        uint256[6] memory ticket;
        uint i = 5;
        while(i>=0){
            ticket[i] = index % (maxNumbers[i] + 1);
            if(i==5){
                ticket[i]++;
            }
            index = index / (maxNumbers[i] + 1);
            if(i == 0) {
                return (ticket[0], ticket[1], ticket[2], ticket[3], ticket[4], ticket[5]);
            }
            i -= 1;
        }
        return (ticket[0], ticket[1], ticket[2], ticket[3], ticket[4], ticket[5]);
    }

    function declareResults(
        uint256 gameId,
        uint256[] memory _randomWords
    ) public {
        require(msg.sender == RNGManager, "Only RNG Manager can declare results");
        if(games[gameId].status != Status.Closed){
            games[gameId].status = Status.Closed;
            (uint256 winner1, uint256 winner2, uint256 winner3) = (_randomWords[0] % poolCapacity, _randomWords[1] % poolCapacity, _randomWords[2] % poolCapacity);
            if(winner1 == winner2){
                winner2 = (winner2 + 1) % poolCapacity;
            }
            if(winner1 == winner3){
                winner3 = (winner3 + 1) % poolCapacity;
            }
            if(winner2 == winner3){
                winner3 = (winner3 + 1) % poolCapacity;
            }
            if(winner1 == winner3){
                winner3 = (winner3 + 1) % poolCapacity;
            }
            winners[gameId][0] = winner1;
            winners[gameId][1] = winner2;
            winners[gameId][2] = winner3;
            // userGeneratedRewardForReferrer[gameMembers[gameId][winner1]] += winningAmounts[0] / 10;
            // userGeneratedRewardForReferrer[gameMembers[gameId][winner2]] += winningAmounts[1] / 10;
            // userGeneratedRewardForReferrer[gameMembers[gameId][winner3]] += winningAmounts[2] / 10;
            vault.distributePoolPrize(gameMembers[gameId][winner1], gameMembers[gameId][winner2], gameMembers[gameId][winner3], winningAmounts, jackpot);

            emit WinnerAnnounced(gameMembers[gameId][winner1], gameMembers[gameId][winner2], gameMembers[gameId][winner3], gameId, winningAmounts);
        }
    }

    function getMyTicketIds(address _user, uint256 _gameId) public view returns(uint256[] memory) {
        uint256[] memory myTicketIds = new uint256[](numberOfTicketsOfUser[_gameId][_user]);
        uint256 count = 0;
        for(uint256 i = 0; i < gameMembers[_gameId].length; i++) {
            if(gameMembers[_gameId][i] == _user) {
                myTicketIds[count] = i;
                count++;
            }
        }
        return myTicketIds;
    }

    function getMembers(uint256 _gameId, uint256 _index) public view returns(address results){
        results = gameMembers[_gameId][_index];
    }

    function getTickets(uint256 _gameId, uint256 _index) public view returns(uint256 results){
        results = gameTickets[_gameId][_index];
    }

    function gameWinners(uint256 _gameId, uint256 _index) public view returns(address results){
        results = gameMembers[_gameId][winners[_gameId][_index]];
    }
    
    function gameWinningAmounts(uint256 _index) public view returns(uint256){
        return winningAmounts[_index];
    }

    function gameWinnerTickets(uint256 _gameId, uint256 _index) public view returns(uint256 results){
        results = gameTickets[_gameId][winners[_gameId][_index]];
    }

    function setRNGManager(address _rngManager) external {
        require(msg.sender == owner, "Only owner can set RNG Manager");
        RNGManager = _rngManager;
    }

    function setEventContract(address _eventContract) external {
        require(msg.sender == owner, "Only owner can set Event Contract");
        eventContract = _eventContract;
    }

    function getUserParticipatedGames(address _user) public view returns(uint256[] memory) {
        return userParticipatedGames[_user];
    }

    function testEvent() public {
        address arr0 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        address arr1 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        address arr2 = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100000000;
        amounts[1] = 200000000;
        amounts[2] = 300000000;
        emit WinnerAnnounced(arr0, arr1, arr2, 1, amounts);
    }
}