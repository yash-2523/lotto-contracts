// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface ILottoGame {
    event TicketBought(address buyer, uint256 gameId, uint256[] ticketId);
    event WinnerAnnounced(
        address winner1,
        address winner2,
        address winner3,
        uint256 gameId,
        uint256[] rewards
    );

    function batchBuyTickets(
        uint256 _numberOfTickets,
        string memory _referrerUsername,
        string memory _username,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function buyTickets(
        string memory _referrerUsername,
        string memory _username,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function declareResults(
        uint256 gameId,
        uint256[] memory _randomWords
    ) external;

    function gameCount() external view returns (uint256);

    function gameMembers(uint256, uint256) external view returns (address);

    function gameTickets(uint256, uint256) external view returns (uint256);

    function gameWinnerTickets(
        uint256 _gameId,
        uint256 _index
    ) external view returns (uint256 results);

    function gameWinners(
        uint256 _gameId,
        uint256 _index
    ) external view returns (address results);

    function gameWinningAmounts(uint256 _index) external view returns (uint256);

    function games(
        uint256
    )
        external
        view
        returns (
            uint256 id,
            uint256 startTime,
            uint256 membersFilled,
            uint8 status
        );

    function getMembers(
        uint256 _gameId,
        uint256 _index
    ) external view returns (address results);

    function getMyTicketIds(
        address _user,
        uint256 _gameId
    ) external view returns (uint256[] memory);

    function getTickets(
        uint256 _gameId,
        uint256 _index
    ) external view returns (uint256 results);

    function hashedMessage() external view returns (bytes32);

    function jackpot() external view returns (uint256);

    function numberOfTicketsOfUser(
        uint256,
        address
    ) external view returns (uint256);

    function owner() external view returns (address);

    function poolCapacity() external view returns (uint256);

    function setRNGManager(address _rngManager) external;

    function stableCoin() external view returns (address);

    function startTime() external view returns (uint256);

    function testEvent() external;

    function ticketPrice() external view returns (uint256);

    function tickets(
        uint256
    )
        external
        view
        returns (
            uint256 num1,
            uint256 num2,
            uint256 num3,
            uint256 num4,
            uint256 num5,
            uint256 joker
        );

    function userGeneratedRewardForReferrer(
        address
    ) external view returns (uint256);

    function userParticipatedGames(
        address,
        uint256
    ) external view returns (uint256);

    function vault() external view returns (address);

    function winners(uint256, uint256) external view returns (uint256);

    function winningAmounts(uint256) external view returns (uint256);
}
