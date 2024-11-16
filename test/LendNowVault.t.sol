// SPDX-License-Identifier: UNLICESNED

pragma solidity 0.8.18;
import {Test, console2} from "forge-std/Test.sol";
import {LendNowVault} from "src/LendNowVault.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {ERC20PoolFactory} from "ajna-core/src/ERC20PoolFactory.sol";

contract LendNowVaultTest is Test {
    LendNowVault t;
    ERC20Mock ajna;
    ERC20Mock collateral;
    ERC20Mock quote;
    ERC20PoolFactory ajnaPoolFactory;
    ERC20Pool pool;

    function setUp() public {
        ajnaPoolFactory = new ERC20PoolFactory(address(ajna));
        pool = ajnaPoolFactory.deployPool(collateral, quote, 0.01e18);
        t = new LendNowVault();
    }

    function test_getPrice() public {
        console2.log(t.getPriceIndex());
    }
}