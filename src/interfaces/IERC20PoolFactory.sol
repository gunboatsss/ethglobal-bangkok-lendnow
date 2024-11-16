pragma solidity 0.8.18;

interface IERC20PoolFactory {
    function deployedPools(bytes32, address, address) external view returns (address);
}