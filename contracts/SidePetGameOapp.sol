// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract SidePetGameOApp is OApp, OAppOptionsType3, Ownable {
    /// @notice LayerZero Endpoint ID for the primary chain (Avalanche)
    uint32 public constant PRIMARY_EID = 30106;

    /// @notice Message type for game actions
    uint16 public constant GAME_MSG = 1;

    /// @notice Game action types (must match PrimaryPetGameOApp)
    uint8 public constant CREATE = 1;
    uint8 public constant FEED = 2;
    uint8 public constant TRAIN = 3;
    uint8 public constant PLAY = 4;
    uint8 public constant FIRST_AID = 5;
    uint8 public constant SLEEP = 6;
    uint8 public constant WAKE = 7;

    /// @notice Initialize with Endpoint V2 and owner address
    /// @param _endpoint The local chain's LayerZero Endpoint V2 address
    /// @param _owner    The address permitted to configure this OApp
    constructor(address _endpoint, address _owner) 
        OApp(_endpoint, _owner) 
        OAppOptionsType3(_endpoint) 
        Ownable(_owner) 
    {}

    // ──────────────────────────────────────────────────────────────────────────────
    // Cross-chain send functions (forward actions to primary chain)
    // ──────────────────────────────────────────────────────────────────────────────

    /// @notice Send a create pet action to the primary chain, forwarding msg.sender as player
    /// @param _options Message execution options
    function sendCreate(bytes calldata _options) external payable {
        _sendAction(CREATE, _options);
    }

    /// @notice Send a feed action to the primary chain
    /// @param _options Message execution options
    function sendFeed(bytes calldata _options) external payable {
        _sendAction(FEED, _options);
    }

    /// @notice Send a train action to the primary chain
    /// @param _options Message execution options
    function sendTrain(bytes calldata _options) external payable {
        _sendAction(TRAIN, _options);
    }

    /// @notice Send a play action to the primary chain
    /// @param _options Message execution options
    function sendPlay(bytes calldata _options) external payable {
        _sendAction(PLAY, _options);
    }

    /// @notice Send a first aid action to the primary chain
    /// @param _options Message execution options
    function sendFirstAid(bytes calldata _options) external payable {
        _sendAction(FIRST_AID, _options);
    }

    /// @notice Send a sleep action to the primary chain
    /// @param _options Message execution options
    function sendSleep(bytes calldata _options) external payable {
        _sendAction(SLEEP, _options);
    }

    /// @notice Send a wake action to the primary chain
    /// @param _options Message execution options
    function sendWake(bytes calldata _options) external payable {
        _sendAction(WAKE, _options);
    }

    function _sendAction(uint8 _action, bytes calldata _options) internal {
        // Encode action + player address (msg.sender) for forwarding
        bytes memory _message = abi.encode(_action, msg.sender);
        _lzSend(
            PRIMARY_EID,
            _message,
            combineOptions(PRIMARY_EID, GAME_MSG, _options),
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
        bytes memory _message = abi.encode(CREATE, address(0)); // Dummy address for quote
        fee = _quote(PRIMARY_EID, _message, combineOptions(PRIMARY_EID, GAME_MSG, _options), _payInLzToken);
    }

    function quoteSendFeed(
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(FEED, address(0));
        fee = _quote(PRIMARY_EID, _message, combineOptions(PRIMARY_EID, GAME_MSG, _options), _payInLzToken);
    }

    function quoteSendTrain(
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(TRAIN, address(0));
        fee = _quote(PRIMARY_EID, _message, combineOptions(PRIMARY_EID, GAME_MSG, _options), _payInLzToken);
    }

    function quoteSendPlay(
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(PLAY, address(0));
        fee = _quote(PRIMARY_EID, _message, combineOptions(PRIMARY_EID, GAME_MSG, _options), _payInLzToken);
    }

    function quoteSendFirstAid(
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(FIRST_AID, address(0));
        fee = _quote(PRIMARY_EID, _message, combineOptions(PRIMARY_EID, GAME_MSG, _options), _payInLzToken);
    }

    function quoteSendSleep(
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(SLEEP, address(0));
        fee = _quote(PRIMARY_EID, _message, combineOptions(PRIMARY_EID, GAME_MSG, _options), _payInLzToken);
    }

    function quoteSendWake(
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(WAKE, address(0));
        fee = _quote(PRIMARY_EID, _message, combineOptions(PRIMARY_EID, GAME_MSG, _options), _payInLzToken);
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // Receive logic (unused on side chain - revert to prevent accidental updates)
    // ──────────────────────────────────────────────────────────────────────────────

    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata /*_message*/,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        revert("Side chain does not process receives");
    }
}
