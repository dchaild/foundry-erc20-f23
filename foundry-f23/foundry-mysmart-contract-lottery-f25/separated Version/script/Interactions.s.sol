// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {console} from "forge-std/console.sol";
import {LinkToken} from "test/mocks/LinkToken.sol"; // Assuming this path is correct, if not, it might need adjustment too.
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";


contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        // Create a new subscription
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    

    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        console.log("Creating subscription on VRF Chain Id:", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription created with ID:", subId);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");
        return (subId, vrfCoordinator);
        
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
    
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // LINK tokens are 18 decimals
    
    function fundSubscriptionUsingConfig() public { 
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator, linkToken, subId);
    }
    function fundSubscription(address vrfCoordinator, address linkToken, uint256 subId) public {
        console.log("Funding subscription on VRF Chain Id:", block.chainid);
        console.log("Using VRF Coordinator:", vrfCoordinator);
        console.log("Using LINK token:", linkToken);
        console.log("Funding subscription ID:", subId);
        if(block.chainid == LOCAL_CHAIN_ID) {
        vm.startBroadcast();
        // Fund the subscription
        VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
        vm.stopBroadcast();
        console.log("Subscription funded with", FUND_AMOUNT / 1e18, "LINK");
        } else {

        vm.startBroadcast();
        LinkToken(linkToken).transferAndCall(
            vrfCoordinator,
            FUND_AMOUNT,
            abi.encode(subId)
        );
        vm.stopBroadcast();

        console.log("On a non-local network, please fund the subscription with LINK tokens manually.");
        
        }
       console.log("Funding process complete.");
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        addConsumer( mostRecentDeployed, vrfCoordinator, subId);
    }

    function addConsumer(address contractToAddtoVrf, address vrfCoordinator, uint256 subId) public {
        console.log("Adding consumer to subscription on VRF Chain Id:", block.chainid);
        console.log("Using VRF Coordinator:", vrfCoordinator);
        console.log("Using subscription ID:", subId);
        console.log("Adding Raffle contract as consumer:", contractToAddtoVrf);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddtoVrf);
        vm.stopBroadcast();
        console.log("Consumer added successfully.");
    }

    function run() public {
        // You can pass the raffle address here if needed
        // addConsumerUsingConfig(raffleAddress);
        address mostRecentDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentDeployed);
    }
}