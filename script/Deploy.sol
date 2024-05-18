// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import "../src/wstBTC.sol";
import "../src/offChainSignatureAggregator.sol";
import "../src/AddressesProvider.sol";


contract CounterScript is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address deployer = address(0x1);
        AddressesProvider ap = new AddressesProvider(deployer);
        wstBTC impl = new wstBTC(address(ap));
        impl.initialize(address(ap));
        ap.setTokenImpl(address(impl));
        new offChainSignatureAggregator(address(ap.getToken()));
        vm.stopBroadcast(); 
    }
}
