// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract PetGameOApp is OApp, OAppOptionsType3, Ownable {
    /// @notice LayerZero Endpoint ID for Avalanche Mainnet
    uint32 public constant AVALANCHE_EID = 30106;

    /// @notice Message type for game actions
    uint16 public constant GAME_MSG = 1;

    /// @notice Game action types
    uint8 public constant CREATE = 1;
    uint8 public constant FEED = 2;
    uint8 public constant TRAIN = 3;
    uint8 public constant PLAY = 4;
    uint8 public constant FIRST_AID = 5;
    uint8 public constant SLEEP = 6;

    /// @notice Cooldown periods (in seconds)
    uint256 public constant FEED_COOLDOWN = 5 minutes;
    uint256 public constant TRAIN_COOLDOWN = 3 minutes;
    uint256 public constant PLAY_COOLDOWN = 2 minutes;
    uint256 public constant FIRST_AID_COOLDOWN = 10 minutes;
    uint256 public constant SLEEP_THRESHOLD = 50; // Tiredness threshold to sleep
    uint256 public constant SLEEP_DURATION = 10 minutes;

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

    /// @notice Initialize with Endpoint V2 and owner address
    /// @param _endpoint The local chain's LayerZero Endpoint V2 address
    /// @param _owner    The address permitted to configure this OApp
    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) OAppOptionsType3(_endpoint) Ownable(_owner) {}

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

	// Possible Issue with 0 health resulting in no pet instead of dead pet
        if (pet.health == 0) revert("No pet exists");

        // Simple check for sleeping: cannot perform actions while sleeping
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
            // Reduce tiredness over sleep (simplified: will be applied on wake)
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
    // Local (non-cross-chain) action functions
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

    // ──────────────────────────────────────────────────────────────────────────────
    // Cross-chain send functions (for side chains)
    // ──────────────────────────────────────────────────────────────────────────────

    /// @notice Send a create pet action to the primary chain (Avalanche)
    /// @param _options Message execution options
    function sendCreate(bytes calldata _options) external payable {
        _sendAction(CREATE, AVALANCHE_EID, _options);
    }

    /// @notice Send a feed action to the primary chain
    /// @param _options Message execution options
    function sendFeed(bytes calldata _options) external payable {
        _sendAction(FEED, AVALANCHE_EID, _options);
    }

    /// @notice Send a train action to the primary chain
    /// @param _options Message execution options
    function sendTrain(bytes calldata _options) external payable {
        _sendAction(TRAIN, AVALANCHE_EID, _options);
    }

    /// @notice Send a play action to the primary chain
    /// @param _options Message execution options
    function sendPlay(bytes calldata _options) external payable {
        _sendAction(PLAY, AVALANCHE_EID, _options);
    }

    /// @notice Send a first aid action to the primary chain
    /// @param _options Message execution options
    function sendFirstAid(bytes calldata _options) external payable {
        _sendAction(FIRST_AID, AVALANCHE_EID, _options);
    }

    /// @notice Send a sleep action to the primary chain
    /// @param _options Message execution options
    function sendSleep(bytes calldata _options) external payable {
        _sendAction(SLEEP, AVALANCHE_EID, _options);
    }

    function _sendAction(uint8 _action, uint32 _dstEid, bytes calldata _options) internal {
        bytes memory _message = abi.encode(_action);
        _lzSend(
            _dstEid,
            _message,
            combineOptions(_dstEid, GAME_MSG, _options),
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // Quote functions for cross-chain sends
    // ──────────────────────────────────────────────────────────────────────────────

    function quoteSendCreate(
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(CREATE);
        fee = _quote(AVALANCHE_EID, _message, combineOptions(AVALANCHE_EID, GAME_MSG, _options), _payInLzToken);
    }

    function quoteSendFeed(
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(FEED);
        fee = _quote(AVALANCHE_EID, _message, combineOptions(AVALANCHE_EID, GAME_MSG, _options), _payInLzToken);
    }

    function quoteSendTrain(
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(TRAIN);
        fee = _quote(AVALANCHE_EID, _message, combineOptions(AVALANCHE_EID, GAME_MSG, _options), _payInLzToken);
    }

    function quoteSendPlay(
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(PLAY);
        fee = _quote(AVALANCHE_EID, _message, combineOptions(AVALANCHE_EID, GAME_MSG, _options), _payInLzToken);
    }

    function quoteSendFirstAid(
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(FIRST_AID);
        fee = _quote(AVALANCHE_EID, _message, combineOptions(AVALANCHE_EID, GAME_MSG, _options), _payInLzToken);
    }

    function quoteSendSleep(
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(SLEEP);
        fee = _quote(AVALANCHE_EID, _message, combineOptions(AVALANCHE_EID, GAME_MSG, _options), _payInLzToken);
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // Receive logic (only updates state on primary chain)
    // ──────────────────────────────────────────────────────────────────────────────

    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        // Only process on primary chain (Avalanche)
        if (eid() != AVALANCHE_EID) {
            revert("Not primary chain");
        }

        uint8 action = abi.decode(_message, (uint8));
        _executeAction(action, _origin.srcAddress);
    }

    // Note: For side chain deployments of this contract, _lzReceive will revert,
    // ensuring no state updates occur there. The send/quote functions will still work
    // to forward actions to Avalanche.
}
