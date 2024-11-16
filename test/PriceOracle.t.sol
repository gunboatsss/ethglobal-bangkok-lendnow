// SPDX-License-Identifier: UNLISCENED
pragma solidity 0.8.18;
import {Test, console2} from "forge-std/Test.sol";
import {PriceOracle} from "src/PriceOracle.sol";
import {MockPyth, PythStructs} from "./MockPyth.sol";

contract PriceOracleTest is Test {
    PriceOracle po;
    MockPyth pyth;

    function setUp() public {
        pyth = new MockPyth(15 * 60 * 60, 1);
        po = new PriceOracle(address(pyth));
    }

    function test_readConstant() public {
        bytes32 ONE = po.register(PriceOracle.Oracle(1, abi.encode(1e18)));
        assertEq(1e18, po.read(ONE));
    }

    function test_readPyth() public {
        address someone = address(11111111111);
        deal(someone, 1e18);
        vm.startPrank(someone);
        bytes32 eth_id = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
        // bytes32 eurc_id = 0x76fa85158bf14ede77087fe3ae472f66213f6ea2f5b411cb2de472794990fa5c;
        bytes memory updateData = pyth.createPriceFeedUpdateData(eth_id, 3000e10, 1e10, -8, 3000e10, 1e10, 69, 59);
        bytes[] memory dataTopush = new bytes[](1);
        dataTopush[0] = updateData;
        pyth.updatePriceFeeds{value: 1}(dataTopush);
        bytes32 eth_oracle = po.register(PriceOracle.Oracle(2, abi.encode(eth_id)));
        console2.log(po.read(eth_oracle));
    }
}