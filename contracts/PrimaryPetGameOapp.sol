// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract PrimaryPetGameOApp is OApp, OAppOptionsType3, Ownable {
    /// @notice LayerZero Endpoint ID for this primary chain (Avalanche)
    uint32 public immutable PRIMARY_EID;

    /// @notice Message type for game actions
    uint16 public constant GAME_MSG = 1;

    /// @notice Game action types
    uint8 public constant CREATE = 1;
    uint8 public constant FEED = 2;
    uint8 public constant TRAIN = 3;
    uint8 public constant PLAY = 4;
    uint8 public constant FIRST_AID = 5;
    uint8 public constant SLEEP = 6;
    uint8 public constant WAKE = 7;

    /// @notice Cooldown periods (in seconds)
    uint256 public constant FEED_COOLDOWN = 1 hours;
    uint256 public constant TRAIN_COOLDOWN = 30 minutes;
    uint256 public constant PLAY_COOLDOWN = 20 minutes;
    uint256 public constant FIRST_AID_COOLDOWN = 1 hours;
    uint256 public constant SLEEP_THRESHOLD = 50; // Tiredness threshold to sleep
    uint256 public constant SLEEP_DURATION = 8 hours;

    /// @notice Max values for stats
    uint256 public constant MAX_HEALTH = 100;
    uint256 public constant MAX_HAPPINESS = 100;
    uint256 public constant MAX_TIREDNESS = 100;
    uint256 public constant MAX_HUNGER = 100;

    /// @notice XP required per level
    uint256 public constant XP_PER_LEVEL = 100;

    struct Pet {
        uint256 health;
        uint256 happiness;
        uint256 level;
        uint256 xp;
        uint256 tiredness;
        uint256 lastInteraction; // Used only for decay calculations
        bool isSleeping;
        uint256 sleepEndTime;
        uint256 rarity;
        uint256 lastClaim;
        uint256 lastTrain; // Tracks train cooldown
        uint256 lastFeed;  // Tracks feed cooldown
        uint256 hunger;    // Hunger stat
        uint256 lastPlay;  // Tracks play cooldown
        uint256 lastFirstAid; // Tracks first aid cooldown
    }

    /// @notice Mapping of player address to their Pet
    mapping(address => Pet) public pets;

    /// @notice Initialize with Endpoint V2, primary EID, and owner address
    /// @param _endpoint The local chain's LayerZero Endpoint V2 address
    /// @param _primaryEid The EID of this primary chain
    /// @param _owner    The address permitted to configure this OApp
    constructor(
        address _endpoint, 
        uint32 _primaryEid, 
        address _owner
    ) OApp(_endpoint, _owner) OAppOptionsType3(_endpoint) Ownable(_owner) {
        PRIMARY_EID = _primaryEid;
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // Internal execution logic for actions
    // ──────────────────────────────────────────────────────────────────────────────

    function _executeAction(uint8 _action, address _player) internal {
        uint256 now = block.timestamp;
        Pet storage pet = pets[_player];

        if (_action == CREATE) {
            if (pet.health != 0) revert("Pet already exists");
            pets[_player] = Pet({
                health: 100,
                happiness: 50,
                level: 1,
                xp: 0,
                tiredness: 0,
                lastInteraction: now,
                isSleeping: false,
                sleepEndTime: 0,
                rarity: 1, // Common rarity
                lastClaim: 0,
                lastTrain: 0,
                lastFeed: 0,
                hunger: 0,
                lastPlay: 0,
                lastFirstAid: 0
            });
            return;
        }

        if (pet.health == 0) revert("No pet exists");

        // Block actions if sleeping and sleep not ended
        if (pet.isSleeping && now < pet.sleepEndTime) revert("Pet is sleeping");

        if (_action == FEED) {
            if (now < pet.lastFeed + FEED_COOLDOWN) revert("Feed on cooldown");
            pet.hunger = 0;
            pet.happiness = _bound(pet.happiness + 10, 0, MAX_HAPPINESS);
            pet.lastFeed = now;
        } else if (_action == TRAIN) {
            if (now < pet.lastTrain + TRAIN_COOLDOWN) revert("Train on cooldown");
            pet.xp += 10;
            pet.tiredness = _bound(pet.tiredness + 20, 0, MAX_TIREDNESS);
            pet.lastTrain = now;
            // Level up logic
            if (pet.xp >= pet.level * XP_PER_LEVEL) {
                pet.level++;
                pet.xp = 0;
                pet.health = _bound(pet.health + 10, 0, MAX_HEALTH);
            }
        } else if (_action == PLAY) {
            if (now < pet.lastPlay + PLAY_COOLDOWN) revert("Play on cooldown");
            pet.happiness = _bound(pet.happiness + 15, 0, MAX_HAPPINESS);
            pet.tiredness = _bound(pet.tiredness + 10, 0, MAX_TIREDNESS);
            pet.lastPlay = now;
        } else if (_action == FIRST_AID) {
            if (now < pet.lastFirstAid + FIRST_AID_COOLDOWN) revert("First aid on cooldown");
            pet.health = _bound(pet.health + 30, 0, MAX_HEALTH);
            pet.lastFirstAid = now;
        } else if (_action == SLEEP) {
            if (pet.tiredness <= SLEEP_THRESHOLD) revert("Not tired enough to sleep");
            pet.isSleeping = true;
            pet.sleepEndTime = now + SLEEP_DURATION;
        } else if (_action == WAKE) {
            if (!pet.isSleeping) revert("Pet is not sleeping");
            if (now < pet.sleepEndTime) revert("Sleep not ended yet");
            
            // Apply recovery benefits
            pet.tiredness = 0;
            pet.health = _bound(pet.health + (MAX_HEALTH / 5), 0, MAX_HEALTH); // +20% health
            pet.hunger = _bound(pet.hunger - 20, 0, MAX_HUNGER); // Reduce hunger
            pet.xp += 5; // Small XP for resting well
            pet.happiness = _bound(pet.happiness + 5, 0, MAX_HAPPINESS); // Gentle wake bonus
            
            // Check level up from XP
            if (pet.xp >= pet.level * XP_PER_LEVEL) {
                pet.level++;
                pet.xp = 0;
                pet.health = _bound(pet.health + 10, 0, MAX_HEALTH);
            }
            
            // Reset flags
            pet.isSleeping = false;
            pet.sleepEndTime = 0;
        } else {
            revert("Invalid action");
        }

        pet.lastInteraction = now;
    }

    /// @dev Helper to bound a value between min and max
    function _bound(uint256 _value, uint256 _min, uint256 _max) internal pure returns (uint256) {
        return _value < _min ? _min : (_value > _max ? _max : _value);
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // Local (non-cross-chain) action functions - only callable on primary chain
    // ──────────────────────────────────────────────────────────────────────────────

    function createPet() external {
        _executeAction(CREATE, msg.sender);
    }

    function feed() external {
        _executeAction(FEED, msg.sender);
    }

    function train() external {
        _executeAction(TRAIN, msg.sender);
    }

    function play() external {
        _executeAction(PLAY, msg.sender);
    }

    function firstAid() external {
        _executeAction(FIRST_AID, msg.sender);
    }

    function sleep() external {
        _executeAction(SLEEP, msg.sender);
    }

    function wake() external {
        _executeAction(WAKE, msg.sender);
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // Receive logic (processes cross-chain actions from side chains)
    // ──────────────────────────────────────────────────────────────────────────────

    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        // Decode action and player address (forwarded from side chain)
        (uint8 action, address player) = abi.decode(_message, (uint8, address));
        _executeAction(action, player);
    }

    // Optional: View function for real-time pet status
    function getPetStatus(address _player) external view returns (Pet memory effectivePet) {
        effectivePet = pets[_player];
        uint256 now = block.timestamp;
        
        // Preview wake benefits if sleep ended
        if (effectivePet.isSleeping && now >= effectivePet.sleepEndTime) {
            effectivePet.tiredness = 0;
            effectivePet.health = _bound(effectivePet.health + (MAX_HEALTH / 5), 0, MAX_HEALTH);
            // Add more previews/decays as needed
        }
    }
}
