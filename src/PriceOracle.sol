pragma solidity 0.8.18;

import {IPyth} from "./interfaces/IPyth.sol";
import {PythStructs} from "./interfaces/PythStructs.sol";
import {ContractRegistry} from "./interfaces/flare/ContractRegistry.sol";
import {TestFtsoV2Interface} from "./interfaces/flare/TestFtsoV2Interface.sol";

interface ISelfKisser {
    /// @notice Thrown if SelfKisser dead.
    error Dead();

    /// @notice Thrown if oracle not supported.
    /// @param oracle The oracle not supported.
    error OracleNotSupported(address oracle);

    /// @notice Emitted when SelfKisser killed.
    /// @param caller The caller's address.
    event Killed(address indexed caller);

    /// @notice Emitted when support for oracle added.
    /// @param caller The caller's address.
    /// @param oracle The oracle that support got added.
    event OracleSupported(address indexed caller, address indexed oracle);

    /// @notice Emitted when support for oracle removed.
    /// @param caller The caller's address.
    /// @param oracle The oracle that support got removed.
    event OracleUnsupported(address indexed caller, address indexed oracle);

    /// @notice Emitted when new address kissed on an oracle.
    /// @param caller The caller's address.
    /// @param oracle The oracle on which address `who` got kissed on.
    /// @param who The address that got kissed on oracle `oracle`.
    event SelfKissed(
        address indexed caller, address indexed oracle, address indexed who
    );

    // -- User Functionality --

    /// @notice Kisses caller on oracle `oracle`.
    ///
    /// @dev Reverts if oracle `oracle` not supported.
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to kiss the caller on.
    function selfKiss(address oracle) external;

    /// @notice Kisses address `who` on oracle `oracle`.
    ///
    /// @dev Reverts if oracle `oracle` not supported.
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to kiss address `who` on.
    /// @param who The address to kiss on oracle `oracle`.
    function selfKiss(address oracle, address who) external;

    // -- View Functionality --

    /// @notice Returns whether oracle `oracle` is supported.
    /// @param oracle The oracle to check whether its supported.
    /// @return True if oracle supported, false otherwise.
    function oracles(address oracle) external view returns (bool);

    /// @notice Returns the list of supported oracles.
    ///
    /// @dev May contain duplicates.
    ///
    /// @return List of supported oracles.
    function oracles() external view returns (address[] memory);

    /// @notice Returns whether SelfKisser is dead.
    /// @return True if SelfKisser dead, false otherwise.
    function dead() external view returns (bool);

    // -- Auth'ed Functionality --

    /// @notice Adds support for oracle `oracle`.
    /// @dev Only callable by auth'ed address.
    ///
    /// @dev Reverts if SelfKisser not auth'ed on oracle `oracle`.
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to add support for.
    function support(address oracle) external;

    /// @notice Removes support for oracle `oracle`.
    /// @dev Only callable by auth'ed address.
    ///
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to remove support for.
    function unsupport(address oracle) external;

    /// @notice Kills the contract.
    /// @dev Only callable by auth'ed address.
    function kill() external;
}

/**
 * @title IChronicle
 *
 * @notice Interface for Chronicle Protocol's oracle products
 */
interface IChronicle {
    /// @notice Returns the oracle's identifier.
    /// @return wat The oracle's identifier.
    function wat() external view returns (bytes32 wat);

    /// @notice Returns the oracle's current value.
    /// @dev Reverts if no value set.
    /// @return value The oracle's current value.
    function read() external view returns (uint value);

    /// @notice Returns the oracle's current value and its age.
    /// @dev Reverts if no value set.
    /// @return value The oracle's current value.
    /// @return age The value's age.
    function readWithAge() external view returns (uint value, uint age);

    /// @notice Returns the oracle's current value.
    /// @return isValid True if value exists, false otherwise.
    /// @return value The oracle's current value if it exists, zero otherwise.
    function tryRead() external view returns (bool isValid, uint value);

    /// @notice Returns the oracle's current value and its age.
    /// @return isValid True if value exists, false otherwise.
    /// @return value The oracle's current value if it exists, zero otherwise.
    /// @return age The value's age if value exists, zero otherwise.
    function tryReadWithAge()
        external
        view
        returns (bool isValid, uint value, uint age);
}

contract PriceOracle {
    uint8 constant CONSTANT_VALUE = 1;
    uint8 constant PYTH_OFFCHAIN = 2;
    uint8 constant FLARE_ORACLE = 3;
    uint8 constant L1SLOAD_CHORNICLE_ORACLE = 4;
    uint8 constant CHORNICLE_ORACLE = 5;
    struct Oracle {
        uint8 oracleType;
        bytes extraData;
    }
    address constant L1SLOAD_PRECOMPILE = 0x0000000000000000000000000000000000000101;
    IPyth immutable pyth;
    mapping (bytes32 oracleId => Oracle) public oracleRegistry;

    constructor(address _pyth) {
        pyth = IPyth(_pyth);
    }

    function selfKiss(address selfKisser, address oracle) public {
        ISelfKisser(selfKisser).selfKiss(oracle);
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
            revert("not implemented");
        }
        // hey scroll!
        else if (oracleType == L1SLOAD_CHORNICLE_ORACLE) {
            address l1OracleAddress = abi.decode(oracleRegistry[oracleId].extraData, (address));
            (bool succ, bytes memory data) = L1SLOAD_PRECOMPILE.staticcall(
                abi.encodePacked(l1OracleAddress, uint256(0))
            );
            if (!succ) {
                revert ("can't read from l1");
            }
            numberD18 = abi.decode(data, (uint256)) & type(uint128).max;
        }
        else if (oracleType == CHORNICLE_ORACLE) {
            address chonicle = abi.decode(oracleRegistry[oracleId].extraData, (address));
            numberD18 = IChronicle(chonicle).read();
        }
    }
}