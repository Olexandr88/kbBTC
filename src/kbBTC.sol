// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

import {IAddressesProvider} from './interfaces/IAddressesProvider.sol';

// implementation contrac† for kinza-babylon token
contract kbBTC is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable  {

    address public immutable provider;

    uint256 public rate = 1e18;

    address public aggregator;

    event RelayToBTCAddress(uint256 amount, string btcAddress, uint256 rate);
    event NewAggregator(address newAggregator);
    event NewRate(uint256 newRate);
    event NewSlash(uint256 newRate);

    constructor(address _provider) {
        _disableInitializers();
        provider = _provider;
    }

    function initialize() public initializer {
        __ERC20_init("Kinza Babylon Staked BTC", "kbBTC");
        // the address provider would be the owner of this contract
         __Ownable_init(provider);
        __UUPSUpgradeable_init();
        // require initialize call by provider
    }

    // override to limit the upgrade call to the owner (which is addressesProvider)
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier onlyAggregator() {
        require(msg.sender == aggregator, "Access Control");
        _;
    }

    function updateAggregator(address newAggregator) external onlyOwner {
        aggregator = newAggregator;
        emit NewAggregator(newAggregator);
    }
    function mint(address to, uint256 amount) external onlyAggregator {
        _mint(to, amount);
    }

    // when users burn the token we would send the same amount * rate, back to the specified btc address
    // if the btc address is in a wrong format we would need the user to contact us and provider proof of the evm address
    function burn(uint256 amount, string memory btcAddress) external {
        _burn(msg.sender, amount);

        emit RelayToBTCAddress(amount, btcAddress, rate);
    }

    // this is the rate of kbBTC toward the underlying amount of BTC backed by the BTC staking positions
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

    // this is a function to remove someone's balance out of supply, only called in emergency
    function emergencyBurn(address burnee, uint256 amount) external onlyOwner {
         _burn(burnee, amount);
    }
}
