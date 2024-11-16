// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {_indexOf, _priceAt, _lpToQuoteToken} from "ajna-core/src/libraries/helpers/PoolHelper.sol";
import "ajna-core/src/interfaces/pool/erc20/IERC20Pool.sol";

import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

contract LendNowVault is ERC4626 {
    uint256 lastPrice = 2000e18;
    uint256 currentIndex;
    IERC20Pool immutable ajnaPool;

    constructor(IERC20Pool ajnaPool_, IERC20 asset_) ERC4626(asset_) {
        ajnaPool = ajnaPool_;
        currentIndex = getPriceIndex();
    }

    function getPriceIndex() public view returns (uint256) {
        return _indexOf(lastPrice);
    }

    function totalAssets() public view override returns (uint256 quoteAmount) {
        uint256 lp_ = ajnaPool.lenderInfo(currentIndex, address(this));
        (uint256 bucketLP_, uint256 bucketCollateral , , uint256 bucketDeposit, ) = ajnaPool.bucketInfo(currentIndex);
        uint256 quoteAmount = _lpToQuoteToken(
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
}