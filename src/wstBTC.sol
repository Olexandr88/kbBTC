// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Ownable} from '@openzeppelin/access/Ownable.sol';

contract wstBTC is Ownable(msg.sender), ERC20 {

    uint256 public rate = 1e18;
    address public aggregator;
    event RelayToBTCAddress(uint256 amount, bytes btcAddress);
    event NewAggregator(address newAggregator);
    event NewRate(uint256 newRate);
    event NewSlash(uint256 newRate);

    constructor() ERC20("Kinza Babylon staked BTC", "wkbBTC") {
    }
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

    // when u burn the token we would send it back to yr btc address
    function burn(uint256 amount, bytes memory btcAddress) external {
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
