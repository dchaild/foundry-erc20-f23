// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract DeployRaffle is Script, CodeConstants {

    uint256 public constant FUND_AMOUNT = 300 ether;

    function run() external returns (Raffle, HelperConfig) {
        return deployRaffle();
    }

    function deployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        vm.allowCheatcodes(address(helperConfig)); // Allow the helper to use cheatcodes
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        uint256 subId;

        // For local testing, we need to create a subscription and add the consumer.
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            // Create Subscription
            subId = VRFCoordinatorV2_5Mock(config.vrfCoordinator).createSubscription();

            // The HelperConfig contract owns the LINK tokens. We prank as it to fund the subscription.
            // Approve the VRF Coordinator to spend the LINK tokens
            LinkToken(config.link).approve(config.vrfCoordinator, FUND_AMOUNT);
            // Fund Subscription
            VRFCoordinatorV2_5Mock(config.vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
            config.subscriptionId = subId;
        } else {
            // On testnets/mainnet, if we don't have a subscriptionId from the config, create one.
            if (config.subscriptionId == 0) {
                // 1. Create the subscription under a new broadcast
                vm.startBroadcast(config.account);
                CreateSubscription createSubscription = new CreateSubscription();
                vm.allowCheatcodes(address(createSubscription));
                (config.subscriptionId, config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator, config.account);
                vm.stopBroadcast();

                // 2. Fund the subscription using the HelperConfig's LINK tokens
                
                FundSubscription fundSubscription = new FundSubscription();
                vm.allowCheatcodes(address(fundSubscription));
                vm.startBroadcast(config.account);
                fundSubscription.fundSubscription(
                    config.vrfCoordinator,
                    config.subscriptionId,
                    config.link,
                    config.account
                );
                vm.stopBroadcast();
            }
      
        }

     // Start a new broadcast for the rest of the deployment
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.subscriptionId,
            config.keyHash,
            config.callbackGasLimit
        );

        // Add the deployed raffle contract as a consumer to the subscription.
        if (block.chainid == LOCAL_CHAIN_ID) {
            VRFCoordinatorV2_5Mock(config.vrfCoordinator).addConsumer(
                config.subscriptionId,
                address(raffle)
            );
        } else {
            AddConsumer addConsumer = new AddConsumer();
            vm.allowCheatcodes(address(addConsumer));
            addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId, config.account);
        }

        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}
