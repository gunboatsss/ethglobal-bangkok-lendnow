// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {_indexOf, _priceAt, _lpToQuoteToken} from "ajna-core/src/libraries/helpers/PoolHelper.sol";
import {IERC20Pool} from "ajna-core/src/interfaces/pool/erc20/IERC20Pool.sol";
import {PriceOracle} from "./PriceOracle.sol";

import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

contract LendNowVault is ERC4626 {

    IERC20Pool immutable public ajnaPool;
    uint256 immutable public bps;
    bytes32 immutable public collateralOracleId;
    bytes32 immutable public quoteOracleId;
    PriceOracle immutable priceOracle;

    uint256 lastPrice;
    uint256 lastUpdate;

    constructor(address ajnaPool_, uint256 bps_, address asset_, bytes32 collateralOracleId_, bytes32 quoteOracleId_, address priceOracle_, string memory symbol_) ERC4626(IERC20(asset_)) ERC20(string.concat("Lend Now! ", symbol_), string.concat("LN!", symbol_)) {
        ajnaPool = IERC20Pool(ajnaPool_);
        require(bps_ < 10000, "bps too high");
        collateralOracleId = collateralOracleId_;
        quoteOracleId = quoteOracleId_;
        bps = bps_;
        priceOracle = PriceOracle(priceOracle_);
    }

    function getPriceIndex() public view returns (uint256) {
        return _indexOf(lastPrice * bps / 10000);
    }

    function updatePrice() public {
        uint256 collateralPrice = priceOracle.read(collateralOracleId);
        uint256 quotePrice = priceOracle.read(quotePrice);
        lastPrice = collateralPrice * 1e18 / quotePrice;
    }

    function totalAssets() public view override returns (uint256 quoteAmount) {
        (uint256 lp_,) = ajnaPool.lenderInfo(getPriceIndex(), address(this));
        (uint256 bucketLP_, uint256 bucketCollateral , , uint256 bucketDeposit, ) = ajnaPool.bucketInfo(getPriceIndex());
        quoteAmount = _lpToQuoteToken(
            bucketLP_,
            bucketCollateral,
            bucketDeposit,
            lp_,
            lastPrice
        );
        if (_underlyingDecimals < 18) {
            quoteAmount = quoteAmount / 10 ** (18 - _underlyingDecimals);
        }
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);
        _asset.approve(address(ajnaPool), assets);
        ajnaPool.addQuoteToken(assets, getPriceIndex(), type(uint256).max);
    }
    
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        ajnaPool.removeQuoteToken(assets, getPriceIndex());
        super._withdraw(caller, receiver, owner, assets, shares);
    }
}
