// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IRNG {
    function airnodeRrp() external view returns (address);

    function fulfillRandomWords(
        bytes32 _requestId,
        bytes memory _data
    ) external;

    function gasPrice() external view returns (uint256);

    function isWhitelisted(address) external view returns (bool);

    function owner() external view returns (address);

    function requestIdToGame(
        bytes32
    )
        external
        view
        returns (uint256 gameId, address gameContract, uint8 gameType);

    function requestRandomNumber(
        uint256 gameId,
        address gameContract,
        uint8 gameType
    ) external;

    
    function backupRNG(
        uint256 gameId,
        address gameContract,
        uint8 gameType
    ) external;

    function setGasPrice(uint256 _gasPrice) external;

    function setSponsorWallet(address _sponsorWallet) external;

    function setWhitelisted(address[] memory _address) external;

    function sponsorWallet() external view returns (address);

    receive() external payable;
}
