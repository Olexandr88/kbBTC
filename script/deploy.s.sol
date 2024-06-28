// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import "../src/kbBTC.sol";
import "../src/offChainSignatureAggregator.sol";
import "../src/AddressesProvider.sol";


contract CounterScript is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address deployer = address(0xDE6A2451A4ACeb6D540Bd216578C84503639EbF1);
        AddressesProvider ap = new AddressesProvider(deployer);
        kbBTC impl = new kbBTC(address(ap));
        ap.setTokenImpl(address(impl));
        offChainSignatureAggregator agg = new offChainSignatureAggregator(address(ap.getToken()));
        ap.updateAggregator(address(agg));
        vm.stopBroadcast(); 
    }
}
