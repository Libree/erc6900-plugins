// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.22;

import {Test, StdUtils} from "forge-std/Test.sol";
import {SubscriptionToken} from "../src/SubscriptionToken.sol";
import {SubscriptionPlugin} from "../src/SubscriptionPlugin.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";

contract SubscriptionPluginTest is Test {
    address subscriptionTokenProxy;
    SubscriptionToken subscriptionToken;
    SubscriptionPlugin subscriptionPlugin;

    address owner = vm.addr(1);
    address usdc = 0x52D800ca262522580CeBAD275395ca6e7598C014;

    function setUp() public {
        vm.startPrank(owner);
        deal(owner, 1 ether);

        bytes memory data = abi.encode(1741855541, 100, usdc);

        subscriptionPlugin = new SubscriptionPlugin();

        subscriptionTokenProxy = Upgrades.deployUUPSProxy(
            "SubscriptionToken.sol",
            abi.encodeCall(
                SubscriptionToken.initialize,
                (owner, "TestNFT", "TEST", "https://example.com", address(subscriptionPlugin), data)
            )
        );

        subscriptionToken = SubscriptionToken(subscriptionTokenProxy);

        vm.stopPrank();
    }

    function testInstallPlugin() public {
        vm.startPrank(owner);
        bytes memory data = abi.encode();

        subscriptionPlugin.pluginManifest();
        subscriptionPlugin.pluginMetadata();
        subscriptionPlugin.onInstall(data);

        vm.stopPrank();
    }

    function testSubscribe() public {
        address subscriber = vm.addr(2);
        vm.startPrank(subscriber);
        deal(subscriber, 1 ether);
        deal(usdc, subscriber, 1000 ether);

        IERC20(usdc).approve(address(subscriptionPlugin), 1000 ether);

        subscriptionPlugin.subscribe(subscriptionTokenProxy);

        vm.stopPrank();
        assertTrue(subscriptionPlugin.isSubscribed(subscriptionTokenProxy, subscriber));
    }

    function testSecondSubscriberSameSubscription() public {
        address subscriber = vm.addr(2);
        vm.startPrank(subscriber);
        deal(subscriber, 1 ether);
        deal(usdc, subscriber, 1000 ether);

        IERC20(usdc).approve(address(subscriptionPlugin), 1000 ether);

        subscriptionPlugin.subscribe(subscriptionTokenProxy);

        vm.stopPrank();

        address subscriber2 = vm.addr(3);

        vm.startPrank(subscriber2);

        deal(subscriber2, 1 ether);
        deal(usdc, subscriber2, 1000 ether);

        IERC20(usdc).approve(address(subscriptionPlugin), 1000 ether);

        subscriptionPlugin.subscribe(subscriptionTokenProxy);

        vm.stopPrank();

        assertTrue(subscriptionPlugin.isSubscribed(subscriptionTokenProxy, subscriber));
        assertTrue(subscriptionPlugin.isSubscribed(subscriptionTokenProxy, subscriber2));
    }

    function testSecondSubscriberDifferentSubscription() public {
        bytes memory data = abi.encode(1741855541, 500, usdc);

        vm.startPrank(owner);
        address subscriptionTokenProxy2 = Upgrades.deployUUPSProxy(
            "SubscriptionToken.sol",
            abi.encodeCall(
                SubscriptionToken.initialize,
                (owner, "TestNFT", "TEST", "https://example.com", address(subscriptionPlugin), data)
            )
        );

        vm.stopPrank();

        address subscriber = vm.addr(2);
        vm.startPrank(subscriber);
        deal(subscriber, 1 ether);
        deal(usdc, subscriber, 1000 ether);

        IERC20(usdc).approve(address(subscriptionPlugin), 1000 ether);

        subscriptionPlugin.subscribe(subscriptionTokenProxy);

        vm.stopPrank();

        address subscriber2 = vm.addr(3);

        vm.startPrank(subscriber2);

        deal(subscriber2, 1 ether);
        deal(usdc, subscriber2, 1000 ether);

        IERC20(usdc).approve(address(subscriptionPlugin), 1000 ether);

        subscriptionPlugin.subscribe(subscriptionTokenProxy2);

        vm.stopPrank();

        assertTrue(subscriptionPlugin.isSubscribed(subscriptionTokenProxy, subscriber));
        assertFalse(subscriptionPlugin.isSubscribed(subscriptionTokenProxy2, subscriber));
        assertTrue(subscriptionPlugin.isSubscribed(subscriptionTokenProxy2, subscriber2));
        assertFalse(subscriptionPlugin.isSubscribed(subscriptionTokenProxy, subscriber2));
    }

    function testSubscriberSameSubscription() public {
        address subscriber = vm.addr(2);
        vm.startPrank(subscriber);
        deal(subscriber, 1 ether);
        deal(usdc, subscriber, 1000 ether);

        IERC20(usdc).approve(address(subscriptionPlugin), 1000 ether);

        subscriptionPlugin.subscribe(subscriptionTokenProxy);

        bytes4 selector = bytes4(keccak256("AlreadySubscribed(address,address,uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, subscriber, subscriptionTokenProxy, 0));

        subscriptionPlugin.subscribe(subscriptionTokenProxy);

        vm.stopPrank();
    }

    function testSubscriberDifferentSubscriptions() public {
        vm.startPrank(owner);
        bytes memory data = abi.encode(1741855541, 500, usdc);
        address subscriptionTokenProxy2 = Upgrades.deployUUPSProxy(
            "SubscriptionToken.sol",
            abi.encodeCall(
                SubscriptionToken.initialize,
                (owner, "TestNFT", "TEST", "https://example.com", address(subscriptionPlugin), data)
            )
        );

        bytes memory data2 = abi.encode(1741855541, 300, usdc);
        address subscriptionTokenProxy3 = Upgrades.deployUUPSProxy(
            "SubscriptionToken.sol",
            abi.encodeCall(
                SubscriptionToken.initialize,
                (owner, "TestNFT", "TEST", "https://example.com", address(subscriptionPlugin), data2)
            )
        );

        vm.stopPrank();

        address subscriber = vm.addr(2);
        vm.startPrank(subscriber);
        deal(subscriber, 1 ether);
        deal(usdc, subscriber, 1000 ether);

        IERC20(usdc).approve(address(subscriptionPlugin), 1000 ether);

        subscriptionPlugin.subscribe(subscriptionTokenProxy);

        subscriptionPlugin.subscribe(subscriptionTokenProxy2);

        subscriptionPlugin.subscribe(subscriptionTokenProxy3);

        vm.stopPrank();

        assertTrue(subscriptionPlugin.isSubscribed(subscriptionTokenProxy, subscriber));
        assertTrue(subscriptionPlugin.isSubscribed(subscriptionTokenProxy2, subscriber));
        assertTrue(subscriptionPlugin.isSubscribed(subscriptionTokenProxy3, subscriber));
    }
}