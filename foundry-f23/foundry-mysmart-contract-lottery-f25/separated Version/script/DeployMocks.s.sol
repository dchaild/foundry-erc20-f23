// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";

contract DeployMocks is Script, CodeConstants {
    function run() external returns (address, address) {
        // This script is only for local anvil chain
        if (block.chainid != LOCAL_CHAIN_ID) {
            revert("This script is only for local anvil chain");
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_LINK_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        return (address(vrfCoordinatorMock), address(linkToken));
    }
}

