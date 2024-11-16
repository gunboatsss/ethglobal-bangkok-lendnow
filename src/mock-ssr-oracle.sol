// SPDX-License-Identifier: UNLISCENSED
pragma solidity 0.8.18;

contract MockSSROracle {
    struct SUSDSData {
        uint96  ssr;  // Sky Savings Rate in per-second value [ray]
        uint120 chi;  // Last computed conversion rate [ray]
        uint40  rho;  // Last computed timestamp [seconds]
    }

    SUSDSData internal _data;

    constructor(uint96 ssr, uint120 chi, uint40 rho) {
        _data.ssr = ssr;
        _data.chi = chi;
        _data.rho = rho;
    }
}