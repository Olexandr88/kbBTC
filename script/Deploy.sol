// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import "../src/kbBTC.sol";
import "../src/offChainSignatureAggregator.sol";
import "../src/AddressesProvider.sol";


contract CounterScript is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address deployer = address(0xCc3fBD1ff6E1e2404D0210823C78ae74085b6235);
        AddressesProvider ap = new AddressesProvider(deployer);
        kbBTC impl = new kbBTC(address(ap));
        ap.setTokenImpl(address(impl));
        offChainSignatureAggregator agg = new offChainSignatureAggregator(address(ap.getToken()));
        ap.updateAggregator(address(agg));
        vm.stopBroadcast(); 
    }
}
