// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, Vm} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";

contract RaffleTest is CodeConstants, Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint256 interval;
    address vrfCoordinator;
    uint256 entranceFee;

    address public PLAYER = makeAddr("player"); // Cheat code to Create a mock player address
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        vm.allowCheatcodes(address(deployer));
        (raffle, helperConfig) = deployer.deployRaffle();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        subscriptionId = config.subscriptionId;
        keyHash = config.keyHash;
        callbackGasLimit = config.callbackGasLimit;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        entranceFee = config.entranceFee;
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /**/ /////////////////////////////////////////////////////////////
    //                Additional tests to be added                //
    ////////////////////////////////////////////////////////////// */
    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        // Assert
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // Act
        address playerRecorded = raffle.getPlayer(0);

        // Assert
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        // Arrange
        vm.prank(PLAYER);
        // Assert
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        // Act
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowEntranceWhenRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // Act
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        // Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

     /**/ /////////////////////////////////////////////////////////////
    //                    CHECK UPKEEP                               //
    /////////////////////////////////////////////////////////////////*/

    function testCheckUpkeepReturnsFalseIFItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act / Assert
        // This test should pass, as all conditions for upkeep have been met.
        raffle.performUpkeep("");
    }

    modifier enteredRaffle() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepRevertsifCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState raffleState = raffle.getRaffleState();  

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance = currentBalance + entranceFee;
        numPlayers = 1;
        
        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, raffleState));
    
        raffle.performUpkeep("");
    }



    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public  enteredRaffle {
        // Arrange
       

        // Act
         vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        

        bytes32 requestIdTopic = entries[1].topics[1];
        uint256 requestId = uint256(requestIdTopic);

        // Assert
        assert(uint256(raffle.getRaffleState()) == 1);
        assert(requestId > 0);
    }

     /*
         Below is the same test as on line 276 but in two different versions
     */ /////////////////////////////////////////////////////////////
     
    /**  function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act / Assert
        vm.expectRevert("nonexistent request");
        // We are simulating the VRF Coordinator calling the rawFulfillRandomWords function
        uint256[] memory randomWords = new uint256[](1);
        raffle.rawFulfillRandomWords(0, randomWords);

     /** ################# class version ################# 
     
     
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep() public enteredRaffle{
        // Arrange

        // Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(0, address(raffle));
        // We are simulating the VRF Coordinator calling the rawFulfillRandomWords function
        uint256[] memory randomWords = new uint256[](1);
        raffle.rawFulfillRandomWords(0, randomWords);}
    }
     
     
     
     
     */




  //  }
    /** First version of the same test
    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public {
        // Arrange
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            address entrant = address(uint160(i));
            vm.deal(entrant, STARTING_PLAYER_BALANCE);
            vm.prank(entrant);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 prize = entranceFee * (additionalEntrants + 1);

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestIdTopic = entries[1].topics[1];
        uint256 requestId = uint256(requestIdTopic);

        // Pretend to be the VRF Coordinator
        vm.prank(vrfCoordinator);
        uint256[] memory randomWords = new uint256[](1); // Provide a mock random number array
        raffle.rawFulfillRandomWords(requestId, randomWords);

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerEndingBalance = recentWinner.balance;
        uint256 numPlayers = raffle.getNumberOfPlayers();

        assert(recentWinner != address(0));
        assert(raffleState == Raffle.RaffleState.OPEN);
        assert(winnerEndingBalance == STARTING_PLAYER_BALANCE + prize);
        assert(numPlayers == 0);
    }
    */




    /**/ /////////////////////////////////////////////////////////////
    //                FULFILL RANDOM WORDS                          //
    ////////////////////////////////////////////////////////////////*/

    modifier skipFork() {
        if (block.chainid != CodeConstants.LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

   function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public enteredRaffle skipFork {
        //  Arrange - this is Mocking the VRF Coordinator using the VRFCoordinatorV2_5Mock
        // a modifier is used to enter the raffle and advance time/block number
        // enteredRaffle modifier is used to enter the raffle and advance time/block number


        // Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
        // We are simulating the VRF Coordinator calling the rawFulfillRandomWords function
      
 
    }
    // ####### Second version of the same test #########
    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public enteredRaffle skipFork {
        // Arrange
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        address expectedWinner = address(1); // Based on the modulus operation with the mock random number being 777

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
           // vm.deal(newPlayer, STARTING_PLAYER_BALANCE);
            //vm.prank(newPlayer);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 startingTimestamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;
       // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 randomRequestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(randomRequestId), address(raffle));

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimestamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1);
        //uint256 numPlayers = raffle.getNumberOfPlayers();

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimestamp > startingTimestamp);
       
    }

}
