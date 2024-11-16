// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {_indexOf, _priceAt, _lpToQuoteToken} from "ajna-core/src/libraries/helpers/PoolHelper.sol";
import {IERC20Pool} from "ajna-core/src/interfaces/pool/erc20/IERC20Pool.sol";

import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

contract LendNowVault is ERC4626 {
    uint256 lastPrice = 2000e18;
    uint256 currentIndex;
    IERC20Pool immutable ajnaPool;

    constructor(IERC20Pool ajnaPool_, IERC20 asset_, string memory symbol_) ERC4626(asset_) ERC20(string.concat("Lend Now! ", symbol_), string.concat("LN!", symbol_)) {
        ajnaPool = ajnaPool_;
        currentIndex = getPriceIndex();
    }

    function getPriceIndex() public view returns (uint256) {
        return _indexOf(lastPrice);
    }

    function totalAssets() public view override returns (uint256 quoteAmount) {
        (uint256 lp_,) = ajnaPool.lenderInfo(currentIndex, address(this));
        (uint256 bucketLP_, uint256 bucketCollateral , , uint256 bucketDeposit, ) = ajnaPool.bucketInfo(currentIndex);
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
        ajnaPool.removeQuoteToken(assets, currentIndex);
        super._withdraw(caller, receiver, owner, assets, shares);
    }
}