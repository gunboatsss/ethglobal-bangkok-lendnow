// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Script} from "forge-std/Script.sol";
import {PriceOracle} from "src/PriceOracle.sol";
import {LendNowFactory} from "src/LendNowFactory.sol";
import {MockPyth} from "test/MockPyth.sol";
import {ERC20PoolFactory} from "ajna-core/src/ERC20PoolFactory.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Scroll_L1SLOAD_USDS_RateHook} from "src/hooks/Scroll_L1SLOAD_USDS_RateHook.sol";

contract DeployOnScrollDevnet is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        MockPyth pyth = new MockPyth(15 * 60, 1);
        ERC20 mockbwAJNA = new ERC20("Mock bwAJNA", "MbwAJNA");
        ERC20PoolFactory ajnaFactory = new ERC20PoolFactory(address(mockbwAJNA));
        PriceOracle p = new PriceOracle(address(pyth));
        LendNowFactory factory = new LendNowFactory(address(ajnaFactory), address(p));
        Scroll_L1SLOAD_USDS_RateHook i = new Scroll_L1SLOAD_USDS_RateHook(0xDDF89eD9D3dE427d25b3f8C91232F23966a12d82);
    }
}