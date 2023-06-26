// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


import "./interfaces/ILottoGame.sol";
import "./interfaces/IVault.sol";

// Chainlink Implementation
// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// contract RNG is VRFConsumerBaseV2 {

//     enum GameType {
//         Lotto,
//         Vault
//     }

//     struct RNDetails {
//         uint256 gameId;
//         address gameContract;
//         GameType gameType;
//     }

//     VRFCoordinatorV2Interface immutable COORDINATOR;
//     bytes32 immutable keyHash;
//     mapping(uint256 => RNDetails) public requestIdToGame;
//     uint64 immutable s_subscriptionId;
//     uint32 immutable callbackGasLimit = 2500000;
//     uint16 immutable requestConfirmations = 3;

//     mapping(address => bool) public isWhitelisted;

//     constructor(
//         uint64 subscriptionId,
//         address vrfContractAddress,
//         bytes32 _keyHash,
//         address[] memory _whitelisted
//     ) VRFConsumerBaseV2(vrfContractAddress) {
//         COORDINATOR = VRFCoordinatorV2Interface(vrfContractAddress);
//         s_subscriptionId = subscriptionId;
//         keyHash = _keyHash;
//         for (uint256 i = 0; i < _whitelisted.length; i++) {
//             isWhitelisted[_whitelisted[i]] = true;
//         }
//     }

//     function requestRandomNumber(
//         uint256 gameId,
//         address gameContract,
//         GameType gameType
//     ) external {
//         require(isWhitelisted[msg.sender], "RNG: Not whitelisted");
//         uint256 requestId = COORDINATOR.requestRandomWords(
//                 keyHash,
//                 s_subscriptionId,
//                 requestConfirmations,
//                 callbackGasLimit,
//                 gameType == GameType.Lotto ? 3 : 1
//             );
//         requestIdToGame[uint256(requestId)] = RNDetails({
//             gameId: gameId,
//             gameContract: gameContract,
//             gameType: gameType
//         });
//     }

//     function fulfillRandomWords(
//         uint256 _requestId,
//         uint256[] memory _randomWords
//     ) internal override {
//         if (requestIdToGame[_requestId].gameType == GameType.Lotto) {
//             ILottoGame(requestIdToGame[_requestId].gameContract).declareResults(requestIdToGame[_requestId].gameId, _randomWords);
//         } else {
//             IVault(payable(requestIdToGame[_requestId].gameContract)).decalreReferralWinners(requestIdToGame[_requestId].gameId, _randomWords);
//         }
//     }
// }


// API3 Implementation
import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";

contract RNG is RrpRequesterV0 {

    enum GameType {
        Lotto,
        Vault
    }

    struct RNDetails {
        uint256 gameId;
        address gameContract;
        GameType gameType;
    }
    address public immutable owner;
    address payable public sponsorWallet;
    mapping(bytes32 => RNDetails) public requestIdToGame;
    mapping(address => bool) public isWhitelisted;
    address immutable airnodeAddress;
    bytes32 immutable endpointId;
    uint256 public gasPrice = 100000000000000000;

    constructor(
        address _airnodeRrpAddress,
        address _airNodeAddress,
        bytes32 _endpointId,
        address[] memory _whitelisted
    )  RrpRequesterV0(_airnodeRrpAddress) {
        owner = msg.sender;
        airnodeAddress = _airNodeAddress;
        endpointId = _endpointId;
        for (uint256 i = 0; i < _whitelisted.length; i++) {
            isWhitelisted[_whitelisted[i]] = true;
        }
    }

    function setSponsorWallet(address payable _sponsorWallet)
        external
    {
        require(msg.sender == owner, "RNG: Only Owner can call");
        sponsorWallet = _sponsorWallet;
    }

    function setWhitelisted(address[] memory _address)
        external
    {
        require(msg.sender == owner, "RNG: Only Owner can call");
        for (uint256 i = 0; i < _address.length; i++) {
            isWhitelisted[_address[i]] = true;
        }
    }

    function setGasPrice(uint256 _gasPrice)
        external
    {
        require(msg.sender == owner, "RNG: Only Owner can call");
        gasPrice = _gasPrice;
    }

    function requestRandomNumber(
        uint256 gameId,
        address gameContract,
        GameType gameType
    ) external {
        require(isWhitelisted[msg.sender], "RNG: Not whitelisted");
        require(sponsorWallet.balance >= gasPrice, "RNG: top-up sponsor wallet");
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnodeAddress,
            endpointId,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillRandomWords.selector,
            abi.encode(bytes32("1u"), bytes32("size"), GameType.Lotto == gameType ? 3 : 1)
        );
        
        requestIdToGame[requestId] = RNDetails({
            gameId: gameId,
            gameContract: gameContract,
            gameType: gameType
        });
    }

    function backupRNG(
        uint256 gameId,
        address gameContract,
        GameType gameType
    ) external {
        require(isWhitelisted[msg.sender], "RNG: Not whitelisted");
        uint256 randomBlock = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, gameId, gameContract, gameType))) % block.number;
        uint256[] memory _randomWords = new uint256[](gameType == GameType.Lotto ? 3 : 1);
        uint256[] memory blocks = new uint256[](3);
        blocks[0] = randomBlock;
        blocks[1] = randomBlock + 1;
        blocks[2] = randomBlock + 2;
        if(blocks[0] == block.number-1) {
            blocks[1] = blocks[0] - 1;
        }
        if(blocks[0] >= block.number-2) {
            blocks[2] = block.number - 3;
        }
        for (uint256 i = 0; i < _randomWords.length; i++) {
            _randomWords[i] = uint256(keccak256(abi.encodePacked(blockhash(blocks[i]), i))) % (10**30);
        }
        if (gameType == GameType.Lotto) {
            ILottoGame(gameContract).declareResults(gameId, _randomWords);
        } else {
            IVault(payable(gameContract)).decalreReferralWinners(gameId, _randomWords);
        }
    }

    function fulfillRandomWords(
        bytes32 _requestId,
        bytes calldata _data
    ) public {
        uint256[] memory _randomWords = abi.decode(_data, (uint256[]));
        if (requestIdToGame[_requestId].gameType == GameType.Lotto) {
            ILottoGame(requestIdToGame[_requestId].gameContract).declareResults(requestIdToGame[_requestId].gameId, _randomWords);
        } else {
            IVault(payable(requestIdToGame[_requestId].gameContract)).decalreReferralWinners(requestIdToGame[_requestId].gameId, _randomWords);
        }
    }

    receive() external payable {}
}

// Blockhash Implementation
// contract RNG {

//     enum GameType {
//         Lotto,
//         Vault
//     }
//     address public immutable owner;
//     mapping(address => bool) public isWhitelisted;

//     constructor(
//         address[] memory _whitelisted
//     ) {
//         owner = msg.sender;
//         for (uint256 i = 0; i < _whitelisted.length; i++) {
//             isWhitelisted[_whitelisted[i]] = true;
//         }
//     }

//     function setWhitelisted(address[] memory _address)
//         external
//     {
//         require(msg.sender == owner, "RNG: Only Owner can call");
//         for (uint256 i = 0; i < _address.length; i++) {
//             isWhitelisted[_address[i]] = true;
//         }
//     }

//     function requestRandomNumber(
//         uint256 gameId,
//         address gameContract,
//         GameType gameType
//     ) external {
//         require(isWhitelisted[msg.sender], "RNG: Not whitelisted");
//         uint256 randomBlock = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, gameId, gameContract, gameType))) % block.number;
//         uint256[] memory _randomWords = new uint256[](gameType == GameType.Lotto ? 3 : 1);
//         uint256[] memory blocks = new uint256[](3);
//         blocks[0] = randomBlock;
//         blocks[1] = randomBlock + 1;
//         blocks[2] = randomBlock + 2;
//         if(blocks[0] == block.number-1) {
//             blocks[1] = blocks[0] - 1;
//         }
//         if(blocks[0] >= block.number-2) {
//             blocks[2] = block.number - 3;
//         }
//         for (uint256 i = 0; i < _randomWords.length; i++) {
//             _randomWords[i] = uint256(keccak256(abi.encodePacked(blockhash(blocks[i]), i))) % (10**30);
//         }
//         if (gameType == GameType.Lotto) {
//             ILottoGame(gameContract).declareResults(gameId, _randomWords);
//         } else {
//             IVault(payable(gameContract)).decalreReferralWinners(gameId, _randomWords);
//         }
//     }

//     receive() external payable {}
// }

