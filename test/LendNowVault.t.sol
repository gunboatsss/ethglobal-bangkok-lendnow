// SPDX-License-Identifier: UNLICESNED

pragma solidity 0.8.18;
import {Test, console2} from "forge-std/Test.sol";
import {LendNowVault} from "src/LendNowVault.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {IERC20Pool} from "ajna-core/src/interfaces/pool/erc20/IERC20Pool.sol";
import {ERC20PoolFactory} from "ajna-core/src/ERC20PoolFactory.sol";

contract LendNowVaultTest is Test {
    LendNowVault t;
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
        t = new LendNowVault(pool, quote, "USDC");
    }

    function test_getPrice() public {
        console2.log(t.getPriceIndex());
    }

    function test_deposit() public {
        quote.mint(address(this), 1e18);
        quote.approve(address(t), 1e18);
        t.deposit(1e18, address(this));
        console2.log(t.balanceOf(address(this)));
        (uint256 lp, ) = pool.lenderInfo(t.getPriceIndex(), address(t));
        console2.log(lp);
    }
}