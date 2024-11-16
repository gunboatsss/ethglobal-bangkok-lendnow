// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockSSROracle} from "src/mock-ssr-oracle.sol";

contract DeployMockSSROracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        MockSSROracle o = new MockSSROracle(1000000001996917783620820123 ,1009386687523739115761266631, 1731317843);
        vm.stopBroadcast();
    }
}