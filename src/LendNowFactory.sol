// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC20PoolFactory} from "./interfaces/IERC20PoolFactory.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {LendNowVault} from "./LendNowVault.sol";

contract LendNowFactory {
    IERC20PoolFactory immutable factory;
    address priceOracle;
    bytes32 constant ERC20_NON_SUBSET_HASH = keccak256("ERC20_NON_SUBSET_HASH");

    address[] public pools;

    constructor(address factory_, address priceOracle_) {
        factory = IERC20PoolFactory(factory_);
        priceOracle = priceOracle_;
    }

    function createNewVault(address _collateral, address _quote, uint256 _bps, bytes32 _collateralOracleId, bytes32 _quotePriceId, address hook_) external returns (address vault) {
        string memory token_sym = IERC20Metadata(_quote).symbol();
        address pool = factory.deployedPools(ERC20_NON_SUBSET_HASH, _collateral, _quote);
        require(pool != address(0));
        vault = address(new LendNowVault(pool, _bps, _quote, _collateralOracleId, _quotePriceId, priceOracle, hook_, token_sym));
        pools.push(vault);
    }
}
