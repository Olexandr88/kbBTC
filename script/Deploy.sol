// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import "../src/wstBTC.sol";
import "../src/offChainSignatureAggregator.sol";

contract CounterScript is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        wstBTC c = new wstBTC();
        new offChainSignatureAggregator(address(c));
        vm.stopBroadcast(); 
    }
}
