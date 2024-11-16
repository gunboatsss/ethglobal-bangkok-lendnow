// SPDX-License-Identifier: UNLICESNED

pragma solidity 0.8.18;
import {Test, console2} from "forge-std/Test.sol";
import {LendNowFactory} from "src/LendNowFactory.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {IERC20Pool} from "ajna-core/src/interfaces/pool/erc20/IERC20Pool.sol";
import {ERC20PoolFactory} from "ajna-core/src/ERC20PoolFactory.sol";

contract LendNowFactoryTest is Test {
    LendNowFactory lendNowFactory;
    ERC20Mock ajna;
    ERC20Mock collateral;
    ERC20Mock quote;
    ERC20PoolFactory ajnaPoolFactory;
    IERC20Pool pool;

    function setUp() public {
        ajna = new ERC20Mock();
        collateral = new ERC20Mock();
        quote = new ERC20Mock();
        ajnaPoolFactory = new ERC20PoolFactory(address(ajna));
        pool = IERC20Pool(ajnaPoolFactory.deployPool(address(collateral), address(quote), 0.01e18));
        lendNowFactory = new LendNowFactory(address(ajnaPoolFactory));
    }

    function test_deployPool() public {
        address vault = lendNowFactory.createNewVault(address(collateral), address(quote), 5000);
        assertFalse(vault == address(0));
    }

}