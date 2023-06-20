// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IEventContract {
    function startTime() external view returns (uint256);
    function endTime() external view returns (uint256);

    function addPoints(address, uint256) external;
}