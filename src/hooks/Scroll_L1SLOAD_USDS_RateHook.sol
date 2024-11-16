// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IInterestHook} from "../InterestHook.sol";

contract Scroll_L1SLOAD_USDS_RateHook is IInterestHook {
    address constant L1SLOAD_PRECOMPILE = 0x0000000000000000000000000000000000000101;
    address immutable USDSOracle;

    struct SUSDSData {
        uint96  ssr;  // Sky Savings Rate in per-second value [ray]
        uint120 chi;  // Last computed conversion rate [ray]
        uint40  rho;  // Last computed timestamp [seconds]
    }

    constructor(address USDSOracle_) {
        USDSOracle = USDSOracle_;
    }
    // hey scroll!
    function getRate() external view returns (uint256) {
        (bool sucess, bytes memory data) = L1SLOAD_PRECOMPILE.staticcall(
            (abi.encodePacked(USDSOracle, uint256(0)))
        );
        if(!sucess) {
            revert("error reading l1");
        }
        uint256 ssr = abi.decode(data, (uint256)) & 0xFFFFFFFFFFFF;
        return ssr * 60 * 60 * 24 * 365;
    }
}