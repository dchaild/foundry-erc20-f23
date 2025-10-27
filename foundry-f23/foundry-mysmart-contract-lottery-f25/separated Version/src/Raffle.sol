// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions
// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

/**
 * @title My sample Raffle Contract
 * @author Musaba D. Chailunga
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    // Errors
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    // Type Declarations
    enum RaffleState {
        OPEN,
        CALCULATING
        }

    // State Variables
    uint256 private immutable i_entranceFee;
    /// @dev the duration of the raffle in seconds
    uint256 private immutable i_interval;
    address private s_owner;
    address payable[] private s_players;
    uint64 private immutable i_subscriptionId;
    uint256 private s_lastTimeStamp;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    bool s_calculatingWinner = false;

    // VRF State
    uint256 public s_requestId;

    // Events

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address _vrfCoordinator,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash; // gas lane
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value > .01 ether, "Minimum entry fee is 0.01 ETH");
        //  require(msg.value >= i_entranceFee, SendMoreToEnterRaffle()); we can't use this as it is in solidity 0.8.4
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (upkeepNeeded, "0x0");
    }

    // Get a random number
    // Use that random number to pick a winner (modulus)
    // Be automated
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        // check if enough time has passed
        //if ((block.timestamp - s_lastTimeStamp) < i_interval) {
        //    revert();
        //}

        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest
        ({
                keyHash: i_keyHash, // gas price
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit, // gas limit for callback
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false})) // Must be empty for VRF v2.5
            });

    s_vrfCoordinator.requestRandomWords(request);

        // 1. Request the random number
        // 2. Wait for the number to be returned
        // 3. Do something with the random number
    }
    // CEI: Checks-Effects-Interactions pattern

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override {
        // Checks
        // Reuires or IF else statements if needed



        // Effects (internal state changes)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);


        // Interactions (external calls)
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        
    
    }
    /**
     * Getter functions
     */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    /**
     * function random() private view returns (uint) {
     *     return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
     * }
     */
    modifier restricted() {
        require(msg.sender == s_owner, "Only the owner can call this function");
        _;
    }
}
