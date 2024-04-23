// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

import "../src/wstBTC.sol";
import "../src/offChainSignatureAggregator.sol";

contract CounterTest is Test {
    address internal signer;
    uint256 internal signerPrivateKey;
    wstBTC internal c;
    offChainSignatureAggregator internal agg;
    function setUp() public {
        signerPrivateKey = 0xA11CE;
        signer = vm.addr(signerPrivateKey);
        vm.startPrank(signer);
        c = new wstBTC();
        agg = new offChainSignatureAggregator(address(c));
        c.updateAggregator(address(agg));
        address[] memory signers = new address[](1);
        bool[] memory valids = new bool[](1);
        signers[0] = signer;
        valids[0] = true;
        agg.setSigners(signers, valids);
    }

    function testMint() public {
        offChainSignatureAggregator.Report memory report = offChainSignatureAggregator.Report({
            receiver: signer,
            amount: 100,
            nonce: 1
        }
            
        );
        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            signerPrivateKey,
            keccak256(abi.encodePacked("\x19\x01", agg.DOMAIN_SEPARATOR(), agg.reportDigest(report)))
        );
        offChainSignatureAggregator.Signature[] memory _rs = new offChainSignatureAggregator.Signature[](1);
        offChainSignatureAggregator.Signature memory rep = offChainSignatureAggregator.Signature({
            v: v,
            r: r,
            s: s
        }       
        );
        _rs[0] = rep;
        agg.mintBTC(report, _rs);

        //assertEq(IERC20(wstBTC.balanceOf(signer), 100);
    }
}