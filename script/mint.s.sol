// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import "../src/wstBTC.sol";
import "../src/offChainSignatureAggregator.sol";


contract CounterScript is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        offChainSignatureAggregator a = offChainSignatureAggregator(0x6c705Cc02342B18134FB8e47b857294068Da2D13);
        offChainSignatureAggregator.Report memory r = offChainSignatureAggregator.Report(
            0x8C390eb9fD466982F5E19378F85b4aD584CeD13b,
            2000000000000000000,
            2
        );
        offChainSignatureAggregator.Signature[] memory _rs = new offChainSignatureAggregator.Signature[](1);
        offChainSignatureAggregator.Signature memory s = offChainSignatureAggregator.Signature(
            0x1c,
            0xec1b9bea2bb2751e97a64a15f3ef8d3557cd98370fe0c7880f189a20496d6ba7,
            0x190ebff9572e88c48ab3622f89e39d4cab11144a0cac4b2210879114f39c1265
        );
        _rs[0] = s;
        a.mintBTC(r, _rs);
        vm.stopBroadcast(); 
    }
}
