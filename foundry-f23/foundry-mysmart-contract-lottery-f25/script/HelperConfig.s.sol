// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    /** VRF Mock Values */
    
    uint96 public constant MOCK_LINK_FEE = uint96(0.25 ether);
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;

    /** LINK / ETH price */
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
   

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {

    error HelperConfig__InvalidChainId();
    // Add your configuration variables and functions here
    struct NetworkConfig {
        uint256 subscriptionId;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint256 interval;
        address vrfCoordinator;
        uint256 entranceFee;
        address link;
        address account;
    }

    
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        // Initialize your network configurations here
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        //localNetworkConfig = getSepoliaEthConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {

        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            // get or create AnvilEthConfig
            return getOrCreateAnvilEthConfig();
            
        } else {
            revert HelperConfig__InvalidChainId();
        }
        
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            subscriptionId: 0,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000, // 500,000 gas limit
            interval: 30, // 30 seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            entranceFee: 0.01 ether,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0xc769FcDf7566B7252CCB0B3641DdB1EDBea992e5 // Replace with your deployer address
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Check if localNetworkConfig is already set
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        // Create VRF Subscription
        // Fund the subscription
        // Return the local network config
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock( 
            MOCK_LINK_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken linkToken = new LinkToken();

        localNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            keyHash: 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15,
            callbackGasLimit: 500000, // 500,000 gas limit
            interval: 30, // 30 seconds
            vrfCoordinator: address(vrfCoordinatorMock),
            entranceFee: 0.01 ether,
            link: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });

        return localNetworkConfig;
                   
    }
}