// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

import {IAddressesProvider} from './interfaces/IAddressesProvider.sol';

contract MockkbBTCV2 is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable  {

    address public immutable provider;
    address public immutable token;

    uint256 public rate = 1e18;

    address public aggregator;

    event RelayToBTCAddress(uint256 amount, string btcAddress);
    event NewAggregator(address newAggregator);
    event NewRate(uint256 newRate);
    event NewSlash(uint256 newRate);

    constructor(address _provider) {
        _disableInitializers();
        token = IAddressesProvider(_provider).getToken();
        provider = _provider;
    }

    function initialize() public reinitializer(2) {
        __ERC20_init("Kinza Babylon Staked BTC V2", "kbBTC");
         __Ownable_init(provider);
        __UUPSUpgradeable_init();
        // require initialize call by provider
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier onlyAggregator() {
        require(msg.sender == aggregator, "Access Control");
        _;
    }

    function testUpgraded() external {

    }

    function updateAggregator(address newAggregator) external onlyOwner {
        aggregator = newAggregator;
        emit NewAggregator(newAggregator);
    }
    function mint(address to, uint256 amount) external onlyAggregator {
        _mint(to, amount);
    }

    // when u burn the token we would send it back to yr btc address
    function burn(uint256 amount, string memory btcAddress) external {
        _burn(msg.sender, amount);

        emit RelayToBTCAddress(amount, btcAddress);
    }

    // this is the rate of wstBTC toward the underlying amount of BTC backed by the BTC staking positions
    // it's expected to increase to reflect yield
    // on extreme occasion (where slashing happens), the rate is reduced.
    function updateYield(uint256 newRate) external onlyAggregator {
        require(newRate > rate, "yield should be positive");
        rate = newRate;
        emit NewRate(newRate);
    }

    function reflectSlash(uint256 newRate)  external onlyAggregator {
        require(newRate < rate, "slash should be positive");
        rate = newRate;
        emit NewSlash(newRate);
    }


}
