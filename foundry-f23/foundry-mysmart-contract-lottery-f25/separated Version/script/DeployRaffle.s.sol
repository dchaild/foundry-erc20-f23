// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {

    function run() external returns (Raffle, HelperConfig, uint256) {
        return deployRaffle();
    }

    function deployRaffle() public returns (Raffle, HelperConfig, uint256) {
        HelperConfig helperConfig = new HelperConfig();
        //AddConsumer addConsumer = new AddConsumer();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            uint64(config.subscriptionId),
            config.keyHash,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId);
        //helperConfig.setConfig(config); // Optionally update the config with new subscriptionId and vrfCoordinator
        

        return (raffle, helperConfig, config.subscriptionId);
    }
}