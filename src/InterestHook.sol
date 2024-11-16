pragma solidity ^0.8.0;

interface IInterestHook {
    function getRate() external returns (uint256);
}