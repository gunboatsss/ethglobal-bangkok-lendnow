// SPDX-License-Identifier: UNLICESNED

pragma solidity 0.8.18;
import {Test, console2} from "forge-std/Test.sol";
import {LendNowVault} from "src/LendNowVault.sol";
import {PriceOracle} from "src/PriceOracle.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {MockUSDC} from "./MockUSDC.sol";
import {IERC20Pool} from "ajna-core/src/interfaces/pool/erc20/IERC20Pool.sol";
import {ERC20PoolFactory} from "ajna-core/src/ERC20PoolFactory.sol";

contract LendNowVaultTest is Test {
    LendNowVault t;
    ERC20Mock ajna;
    ERC20Mock collateral;
    ERC20Mock quote;
    MockUSDC usdc;
    ERC20PoolFactory ajnaPoolFactory;
    IERC20Pool pool;
    PriceOracle po;

    bytes32 THREE_THOUSAND;
    bytes32 ONE;

    function setUp() public {
        ajna = new ERC20Mock();
        collateral = new ERC20Mock();
        quote = new ERC20Mock();
        ajnaPoolFactory = new ERC20PoolFactory(address(ajna));
        pool = IERC20Pool(ajnaPoolFactory.deployPool(address(collateral), address(quote), 0.01e18));
        po = new PriceOracle(address(69)); // skip pyth stuff for now
        THREE_THOUSAND = po.register(PriceOracle.Oracle({
            oracleType: uint8(1),
            extraData: abi.encode(3000e18)
        }));
        ONE = po.register(PriceOracle.Oracle({
            oracleType: uint8(1),
            extraData: abi.encode(1e18)
        }));
        usdc = new MockUSDC();
        console2.log(po.read(THREE_THOUSAND) * 1e18 / po.read(ONE));
        t = new LendNowVault(address(pool), 5000, address(quote), THREE_THOUSAND, ONE, address(po), address(0), "USDC");
    }

    function test_getPrice() public {
        t.updatePrice();
        console2.log(t.getPriceIndex());
    }

    function test_deposit() public {
        quote.mint(address(this), 1e18);
        quote.approve(address(t), 1e18);
        t.updatePrice();
        t.deposit(1e18, address(this));
        console2.log(t.balanceOf(address(this)));
        (uint256 lp, ) = pool.lenderInfo(t.getPriceIndex(), address(t));
        console2.log(lp);
        console2.log(t.totalAssets());
    }

    function test_withdraw() public {
        quote.mint(address(this), 1e18);
        quote.approve(address(t), 1e18);
        t.updatePrice();
        t.deposit(1e18, address(this));
        uint256 balance = t.balanceOf(address(this));
        t.redeem(balance, address(this), address(this));
    }

    function test_sixDecimals() public {
        address pool2 = ajnaPoolFactory.deployPool(address(collateral), address(usdc), 0.01e18);
        LendNowVault v2 = new LendNowVault(
            address(pool2),
            6000,
            address(usdc),
            THREE_THOUSAND,
            ONE,
            address(po),
            address(0),
            "MUSDC"
        );
        usdc.mint(address(this), 1e6);
        usdc.approve(address(v2), 1e6);
        v2.updatePrice();
        v2.deposit(1e6, address(this));
        uint256 balance = v2.balanceOf(address(this));
        console2.log("total assets 6 decimals", v2.totalAssets());
        v2.redeem(balance, address(this), address(this));
    }
}