pragma solidity 0.8.18;

import {IPyth} from "./interfaces/IPyth.sol";
import {PythStructs} from "./interfaces/PythStructs.sol";
import {ContractRegistry} from "./interfaces/flare/ContractRegistry.sol";
import {TestFtsoV2Interface} from "./interfaces/flare/TestFtsoV2Interface.sol";

contract PriceOracleWithFlare {
    uint8 constant CONSTANT_VALUE = 1;
    uint8 constant PYTH_OFFCHAIN = 2;
    uint8 constant FLARE_ORACLE = 3;
    struct Oracle {
        uint8 oracleType;
        bytes extraData;
    }
    IPyth immutable pyth;
    TestFtsoV2Interface immutable ftsoV2;
    mapping (bytes32 oracleId => Oracle) public oracleRegistry;

    constructor(address _pyth) {
        pyth = IPyth(_pyth);
        ftsoV2 = ContractRegistry.getTestFtsoV2();
    }

    function register(Oracle memory oracleData) external returns (bytes32) {
        bytes32 oracleId = keccak256(abi.encode(oracleData));
        if(oracleRegistry[oracleId].oracleType == 0) {
            oracleRegistry[oracleId].oracleType = oracleData.oracleType;
            oracleRegistry[oracleId].extraData = oracleData.extraData;
        }
        return oracleId;
    }

    function read(bytes32 oracleId) external view returns (uint256 numberD18) {
        uint8 oracleType = oracleRegistry[oracleId].oracleType;
        if(oracleType == 0) {
            revert();
        }
        else if (oracleType == CONSTANT_VALUE) {
            numberD18 = abi.decode(oracleRegistry[oracleId].extraData, (uint256));
        }
        else if (oracleType == PYTH_OFFCHAIN) {
            bytes32 pythPriceId = abi.decode(oracleRegistry[oracleId].extraData, (bytes32));
            PythStructs.Price memory p = pyth.getPriceUnsafe(pythPriceId); // YES IT'S DANGEROUS
            uint256 price = uint256(uint64(p.price));
            uint256 conf = p.conf;
            int256 scale = p.expo + 18;
            numberD18 = (scale > 0) ? (price-conf)*10**uint256(scale) : (price-conf)/10**uint256(-scale);
        }
        else if (oracleType == FLARE_ORACLE) {
            bytes21 flarePriceId = abi.decode(oracleRegistry[oracleId].extraData, (bytes21));
            (uint256 feedValue, int8 decimals, ) = ftsoV2.getFeedById(flarePriceId);
            int256 adjust = 18 - decimals;
            if (adjust == 0) {
                numberD18 = feedValue;
            }
            else if (adjust > 0) {
                numberD18 = feedValue * 10 ** uint256(adjust);
            }
            else {
                numberD18 = feedValue * 10 ** uint256(-adjust);
            }
        }
    }
}