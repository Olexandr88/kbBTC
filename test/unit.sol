// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

import "../src/kbBTC.sol";
import "../src/mock/MockkbBTCV2.sol";
import "../src/AddressesProvider.sol";
import "../src/offChainSignatureAggregator.sol";

contract UnitTest is Test {
    address internal signer;
    uint256 internal signerPrivateKey;
    AddressesProvider internal ap;
    kbBTC internal proxyToken;
    offChainSignatureAggregator internal agg;
    function setUp() public {
        signerPrivateKey = 0xA11CE;
        signer = vm.addr(signerPrivateKey);
        vm.startPrank(signer);
        ap = new AddressesProvider(signer);
        kbBTC impl = new kbBTC(address(ap));
        ap.setTokenImpl(address(impl));
        proxyToken = kbBTC(ap.getToken());
        agg = new offChainSignatureAggregator(address(proxyToken));
        ap.updateAggregator(address(agg));
        address[] memory signers = new address[](1);
        bool[] memory valids = new bool[](1);
        signers[0] = signer;
        valids[0] = true;
        agg.setSigners(signers, valids);
    }

    function mint(address receiver, uint256 amount) public {
        uint256 nonce = agg.nonce();
        uint256 beforeBalance = proxyToken.balanceOf(receiver);
        offChainSignatureAggregator.Report memory report = offChainSignatureAggregator.Report({
            receiver: receiver,
            amount: amount,
            nonce: nonce + 1
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
        require(beforeBalance + amount == proxyToken.balanceOf(receiver));
    }

    function burn(address burner, uint256 amount) public {
        require(proxyToken.balanceOf(burner) >= amount);
        uint256 beforeBalance = proxyToken.balanceOf(burner);
        vm.startPrank(burner);
        string memory btcAddress = "tb1pap6uaw5y693cx69d0we2ex6ymclyr2k3esm30p32g20sa94aykrsgjcdec";
        proxyToken.burn(amount, btcAddress);
        require(beforeBalance - amount == proxyToken.balanceOf(burner));
    }

    function upgrade() public {
        uint256 totalSupplyBefore = proxyToken.totalSupply();
        vm.startPrank(signer);
        MockkbBTCV2 newTokenImpl = new MockkbBTCV2(address(ap));
        ap.setTokenImpl(address(newTokenImpl));
        require(proxyToken.totalSupply() == totalSupplyBefore);
        testMint();
        testBurn();
    }

    function testUpgradeReverted() public {
        MockkbBTCV2 newTokenImpl = new MockkbBTCV2(address(ap));
        address stranger = address(0x2);
        vm.startPrank(stranger);
        vm.expectRevert();
        ap.setTokenImpl(address(newTokenImpl));
    }
    function testMint() public {
        address receiver = address(0x1);
        uint256 amount = 1e18;
        mint(receiver, amount);
    }

    function testBurn() public {
        address receiver = address(0x1);
        uint256 amount = 1e18;
        mint(receiver, amount);
        burn(receiver, amount);

    }

    function testEmergencyBurn() public {
        address receiver = address(0x1);
        uint256 amount = 1e18;
        mint(receiver, amount);
        vm.startPrank(signer);
        ap.emergencyBurn(receiver, amount);


    }

    function testUpgrade() public {
        upgrade();
        MockkbBTCV2(address(proxyToken)).testUpgraded();
    }

}