<p align="center">
  <a href="https://layerzero.network">
    <img alt="LayerZero" style="width: 400px" src="https://docs.layerzero.network/img/LayerZero_Logo_Black.svg"/>
  </a>
</p>

<p align="center">
  <a href="https://docs.layerzero.network/" style="color: #a77dff">LayerZero Docs</a>
</p>

<h1 align="center">Omnichain Application (OApp) Example</h1>

<p align="center">Template project for creating custom omnichain applications (<a href="https://docs.layerzero.network/v2/concepts/applications/oapp-standard">OApp</a>) powered by the LayerZero protocol. This example is a verbose demonstration of how to build applications that can send and receive arbitrary messages across different blockchains.</p>

## Table of Contents

- [Prerequisite Knowledge](#prerequisite-knowledge)
  - [How does LayerZero Work](#how-does-layerzero-work)
  - [What is an OApp](#what-is-an-oapp)
  - [Example EVM](#example-evm)
- [Requirements](#requirements)
- [Scaffold this example](#scaffold-this-example)
- [Helper Tasks](#helper-tasks)
- [Setup](#setup)
- [Build](#build)
  - [Compiling your contracts](#compiling-your-contracts)
- [Deploy](#deploy)
- [Enable Messaging](#enable-messaging)
- [Sending Messages](#sending-messages)
- [Next Steps](#next-steps)
  - [Security Stack DVNS](#security0stack-dvns)
  - [Message Execution Options](#message-execution-options)
- [Production Deployment Checklist](#production-deployment-checklist)
- [Appendix](#appendix)
  - [Running Tests](#running-tests)
  - [Adding other chains](#adding-other-chains)
  - [Using Multisigs](#using-multisigs)
  - [LayerZero Hardhat Helper Tasks](#layerzero-hardhat-helper-tasks)
  - [Contract Verification](#contract-verification)
  - [Troubleshooting](#troubleshooting)
    - [Debugging Messages](#debugging-messages)
      - [Message Execution](#message-execution)
    - [Error Codes & Handling](#error-codes-&-handling)

## Prerequisite Knowledge
### How does LayerZero work

<h4>What is LayerZero?</h4>
  LayerZero is an omnichain messaging protocol — a permissionless, open framework designed to securely move information between blockchains. It empowers any application to bring its own security, execution, and cross-chain interaction, providing a predictable and adaptable foundation for decentralized applications living on multiple networks.

<h4>Before LayerZero</h4>

  Before LayerZero, cross-chain communication was a patchwork of monolithic bridges and isolated solutions. Achieving true cross-chain communication was a complex and often fragile endeavor.

  Traditional methods relied on monolithic bridges with centralized verifiers or a fixed set of signers — approaches that imposed rigid structures and created single points of failure. When any component of these systems faltered, every connected application was put at risk, stifling innovation and leaving developers scrambling for secure solutions.

<h4>The LayerZero Framework</h4>

- LayerZero redefines cross-chain interactions by combining several key architectural elements:

    - Immutable Smart Contracts:
      - Non-upgradeable endpoint contracts are deployed on each blockchain. These immutable contracts serve as secure entry and exit points for messages, ensuring consistency and trust across all networks.

    - Configurable Message Libraries:
      - LayerZero offers flexible libraries that developers can select to tailor the way messages are emitted off-chain. This adaptability means applications can optimize message formatting and handling according to specific needs without being tied to a one-size-fits-all solution.

    - Modular Security Owned by the Application:
      - Instead of relying on a centralized verifier network, LayerZero enables each application to configure its own security stack. Developers can choose from various decentralized verifier networks (DVNs) and set parameters like finality and execution rules. This modular approach shifts control to the application, allowing for tailored security that evolves with emerging technologies.

    - Permissionless Execution:
      - By making the execution of cross-chain messages available to anyone, LayerZero ensures that once a message is verified, it can be executed without gatekeepers. This open design removes bottlenecks and facilitates seamless interaction across the blockchain mesh.

**Together, these elements create a robust foundation that makes the following primitives possible.**


### What is an OApp

<h4>Generic Message Passing</h4>

- Send & receive interface:
  - An OApp provides interface methods to send messages (by encoding data into a payload) and receive messages (by decoding that payload and executing business logic) via the LayerZero protocol. This abstraction lets you use the same messaging pattern for a variety of use cases (e.g., DeFi, DAOs, NFT transfers).

- Custom logic on receipt:
  - Each OApp is designed so that developers can plug in their application-specific logic into the message‐handling functions. Whether you’re transferring tokens, votes, or some other data-type, the core design remains the same.

<h4>Quoting and Payment</h4>
  
- Dynamic fee estimation:
  - The standard provides a mechanism to quote the required service fees for sending a cross-chain message in both the native chain token and in the protocol token, ZRO. This quote must match the gas or fee requirements at the time of sending.

- Bundled fee model:
  - The fee paid on the source chain covers all costs: the native chain gas cost and fees for the service workers handling the transaction on the destination chain (e.g., Decentralized Verifier Networks and Executors). This unified fee model simplifies cross-chain transactions for developers and users alike.

<h4>Execution Options and Enforced Settings</h4>
  
- Message execution options:
  - When sending a message, developers can specify execution options — such as the amount of gas to be used on the destination chain or other execution parameters. These options help tailor how the cross-chain message is processed once it arrives.

- Enforced options:
  - To prevent misconfigurations or inconsistent execution, OApps can enforce a set of options (like minimum gas limits) that all senders must adhere to. This ensures that messages are processed reliably and prevents unexpected reverts or failures.

<h4>Peer and Endpoint Management</h4>
  
- Trusted peers:
  - Every deployed OApp must set up trusted peers on the destination chains. This pairing (stored as a simple mapping) tells the protocol where to send messages to or expect messages from.

> **Info:** The peer’s address is stored in a format (such as bytes32) that is interoperable between VMs.

  - Endpoint Integration:
    - All cross-chain messages are sent via a standardized protocol endpoint, which handles the low-level message routing, verification management, and fee management. This endpoint acts as the bridge between disparate chains.

<h4>Administrative and Security Controls</h4>
  
- Admin and delegate roles:
  - The OApp design includes built-in roles for managing and configuring the application. Typically, the contract owner (or admin) holds the authority to update peers, set execution configurations, or transfer admin rights. A separate role, the delegate, can be used to manage critical operations like security configuration updates and block finality settings.

- Security measures:
  - Since cross-chain operations carry extra risk, developers are encouraged to use additional safeguards (e.g., governance controls, multisig wallets, or timelocks) to secure critical roles like the delegate and admin to prevent unauthorized changes.

<h4>Composition (Re-entrancy & Extended Flows)</h4>
  
- Message composition:
  - Beyond simple send/receive operations, the standard can also support composing messages. This “compose” feature allows an OApp to trigger a subsequent call to itself or another contract after a message has been delivered. This is particularly useful for advanced use cases where the cross-chain message results in a series of actions rather than a single event.

<h4>VM-Specific Implementation Notes</h4>

- EVM:
  - The OApp is implemented via Solidity contracts. Developers inherit from base contracts like OApp.sol that provide a complete messaging interface (including enforced options and fee quoting) while allowing custom logic in the _lzReceive function.

- Solana:
  - Instead of inheritance, Solana relies on Cross Program Invocation (CPI) where the LayerZero Endpoint CPI is used. Developers build their OApp program around a set of core instructions that mirror the send/receive flow.

- Aptos Move:
  - The Move-based OApp splits the logic into modular components (such as oapp::oapp, oapp::oapp_core, oapp::oapp_receive, and oapp::oapp_compose). Each module encapsulates parts of the messaging process—from fee quoting to message composition—while preserving the same overall flow.

### Example EVM

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract MyOApp is OApp, OAppOptionsType3 {
    /// @notice Last string received from any remote chain
    string public lastMessage;

    /// @notice Msg type for sending a string, for use in OAppOptionsType3 as an enforced option
    uint16 public constant SEND = 1;

    /// @notice Initialize with Endpoint V2 and owner address
    /// @param _endpoint The local chain's LayerZero Endpoint V2 address
    /// @param _owner    The address permitted to configure this OApp
    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}

    // ──────────────────────────────────────────────────────────────────────────────
    // 0. (Optional) Quote business logic
    //
    // Example: Get a quote from the Endpoint for a cost estimate of sending a message.
    // Replace this to mirror your own send business logic.
    // ──────────────────────────────────────────────────────────────────────────────

    /**
     * @notice Quotes the gas needed to pay for the full omnichain transaction in native gas or ZRO token.
     * @param _dstEid Destination chain's endpoint ID.
     * @param _string The string to send.
     * @param _options Message execution options (e.g., for sending gas to destination).
     * @param _payInLzToken Whether to return fee in ZRO token.
     * @return fee A `MessagingFee` struct containing the calculated gas fee in either the native token or ZRO token.
     */
    function quoteSendString(
        uint32 _dstEid,
        string calldata _string,
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(_string);
        // combineOptions (from OAppOptionsType3) merges enforced options set by the contract owner
        // with any additional execution options provided by the caller
        fee = _quote(_dstEid, _message, combineOptions(_dstEid, SEND, _options), _payInLzToken);
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // 1. Send business logic
    //
    // Example: send a simple string to a remote chain. Replace this with your
    // own state-update logic, then encode whatever data your application needs.
    // ──────────────────────────────────────────────────────────────────────────────

    /// @notice Send a string to a remote OApp on another chain
    /// @param _dstEid   Destination Endpoint ID (uint32)
    /// @param _string  The string to send
    /// @param _options  Execution options for gas on the destination (bytes)
    function sendString(uint32 _dstEid, string calldata _string, bytes calldata _options) external payable {
        // 1. (Optional) Update any local state here.
        //    e.g., record that a message was "sent":
        //    sentCount += 1;

        // 2. Encode any data structures you wish to send into bytes
        //    You can use abi.encode, abi.encodePacked, or directly splice bytes
        //    if you know the format of your data structures
        bytes memory _message = abi.encode(_string);

        // 3. Call OAppSender._lzSend to package and dispatch the cross-chain message
        //    - _dstEid:   remote chain's Endpoint ID
        //    - _message:  ABI-encoded string
        //    - _options:  combined execution options (enforced + caller-provided)
        //    - MessagingFee(msg.value, 0): pay all gas as native token; no ZRO
        //    - payable(msg.sender): refund excess gas to caller
        //
        //    combineOptions (from OAppOptionsType3) merges enforced options set by the contract owner
        //    with any additional execution options provided by the caller
        _lzSend(
            _dstEid,
            _message,
            combineOptions(_dstEid, SEND, _options),
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // 2. Receive business logic
    //
    // Override _lzReceive to decode the incoming bytes and apply your logic.
    // The base OAppReceiver.lzReceive ensures:
    //   • Only the LayerZero Endpoint can call this method
    //   • The sender is a registered peer (peers[srcEid] == origin.sender)
    // ──────────────────────────────────────────────────────────────────────────────

    /// @notice Invoked by OAppReceiver when EndpointV2.lzReceive is called
    /// @dev   _origin    Metadata (source chain, sender address, nonce)
    /// @dev   _guid      Global unique ID for tracking this message
    /// @param _message   ABI-encoded bytes (the string we sent earlier)
    /// @dev   _executor  Executor address that delivered the message
    /// @dev   _extraData Additional data from the Executor (unused here)
    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        // 1. Decode the incoming bytes into a string
        //    You can use abi.decode, abi.decodePacked, or directly splice bytes
        //    if you know the format of your data structures
        string memory _string = abi.decode(_message, (string));

        // 2. Apply your custom logic. In this example, store it in `lastMessage`.
        lastMessage = _string;

        // 3. (Optional) Trigger further on-chain actions.
        //    e.g., emit an event, mint tokens, call another contract, etc.
        //    emit MessageReceived(_origin.srcEid, _string);
    }
}
```

## Requirements

- `Node.js` - `>=18.16.0`
- `pnpm` (recommended) - or another package manager of your choice (npm, yarn)
- `forge` (optional) - `>=0.2.0` for testing, and if not using Hardhat for compilation

## Scaffold this example

Create your local copy of this example:

```bash
pnpm dlx create-lz-oapp@latest --example oapp
```

Specify the directory:

> Where do you want to start your project? › ./my-lz-oapp

select `OApp` and proceed with the installation:

> Which example would you like to use as a starting point? › - Use arrow-keys. Return to submit.
> ❯   OApp

Note that `create-lz-oapp` will also automatically run the dependencies install step for you.

## Helper Tasks

Throughout this walkthrough, helper tasks will be used. For the full list of available helper tasks, refer to the [LayerZero Hardhat Helper Tasks section](#layerzero-hardhat-helper-tasks). All commands can be run at the project root.

## Setup

- Copy `.env.example` into a new `.env`
- Set up your deployer address/account via the `.env`

  - You can specify either `MNEMONIC` or `PRIVATE_KEY`:

    ```
    MNEMONIC="test test test test test test test test test test test junk"
    or...
    PRIVATE_KEY="0xabc...def"
    ```

- Fund this deployer address/account with the native tokens of the chains you want to deploy to. This example by default will deploy to the following chains' testnets: **Base Sepolia** and **Arbitrum Sepolia**.

## Build

### Compiling your contracts

This project supports both `hardhat` and `forge` compilation. By default, the `compile` command will execute both:

```bash
pnpm compile
```

If you prefer one over the other, you can use the tooling-specific commands:

```bash
pnpm compile:forge
pnpm compile:hardhat
```

## Deploy

To deploy the OApp contracts to your desired blockchains, run the following command:

```bash
pnpm hardhat lz:deploy --tags MyOApp
```


Select all the chains you want to deploy the OApp to.

> **Warning:** Using lz:deploy without `tags` will result in all deployment scripts being executed. 

## Enable Messaging
- Wire / Wiring
  - `Wiring` in LayerZero refers to the process of connecting OApps across different blockchains to enable cross-chain communication. The process involves setting peer addresses between OApps, configuring DVNs, and message execution settings. All these actions are done via submitting transactions to the relevant contracts (e.g. OApp, Endpoint) on each chain. Once wired, contracts can send and receive messages between specific source and destination contracts.

After deploying the OApp on the respective chains, you must run the wiring task to enable messaging.

First create a new or modify the existing layerzero config file.

`layerzero.config.ts`

```typescript
import {ExecutorOptionType} from '@layerzerolabs/lz-v2-utilities';
import {OAppEnforcedOption, OmniPointHardhat} from '@layerzerolabs/toolbox-hardhat';
import {EndpointId} from '@layerzerolabs/lz-definitions';
import {generateConnectionsConfig} from '@layerzerolabs/metadata-tools';

const avalancheContract: OmniPointHardhat = {
  eid: EndpointId.AVALANCHE_V2_TESTNET,
  contractName: 'MyOFT',
};

const polygonContract: OmniPointHardhat = {
  eid: EndpointId.AMOY_V2_TESTNET,
  contractName: 'MyOFT',
};

const EVM_ENFORCED_OPTIONS: OAppEnforcedOption[] = [
  {
    msgType: 1,
    optionType: ExecutorOptionType.LZ_RECEIVE,
    gas: 80000,
    value: 0,
  },
];

export default async function () {
  // note: pathways declared here are automatically bidirectional
  // if you declare A,B there's no need to declare B,A
  const connections = await generateConnectionsConfig([
    [
      avalancheContract, // Chain A contract
      polygonContract, // Chain B contract
      [['LayerZero Labs'], []], // [ requiredDVN[], [ optionalDVN[], threshold ] ]
      [1, 1], // [A to B confirmations, B to A confirmations]
      [EVM_ENFORCED_OPTIONS, EVM_ENFORCED_OPTIONS], // Chain B enforcedOptions, Chain A enforcedOptions
    ],
  ]);

  return {
    contracts: [{contract: avalancheContract}, {contract: polygonContract}],
    connections,
  };
}
```

Run the wiring task:

```bash
pnpm hardhat lz:oapp:wire --oapp-config layerzero.config.ts
```

Submit all the transactions to complete wiring. After all transactions confirm, your OApps are wired and can send messages to each other.

## Sending Messages

With your OApps wired, you can now send messages cross-chain.

Send a message from **Base Sepolia** to **Arbitrum Sepolia**:

```bash
pnpm hardhat lz:oapp:send --dst-eid 40231 --string 'Hello from Base!' --network base-sepolia
```

Send a message from **Arbitrum Sepolia** to **Base Sepolia**:

```bash
pnpm hardhat lz:oapp:send --dst-eid 40245 --string 'Hello from Arbitrum!' --network arbitrum-sepolia
```

> :information_source: `40245` and `40231` are the Endpoint IDs of Base Sepolia and Arbitrum Sepolia respectively. The source network is determined by the `--network` flag, not a separate `--src-eid` parameter. View the list of chains and their Endpoint IDs on the [Deployed Endpoints](https://docs.layerzero.network/v2/deployments/deployed-contracts) page.

Upon a successful send, the script will provide you with the link to the message on [LayerZero Scan](https://layerzeroscan.com/).

Once the message is delivered, you will be able to click on the destination transaction hash to verify that the message was received.

Congratulations, you have now sent a message cross-chain!

> If you run into any issues, refer to [Troubleshooting](#troubleshooting).

## Next Steps

Now that you've gone through a simplified walkthrough, here are what you can do next.

- If you are planning to deploy to production, go through the [Production Deployment Checklist](#production-deployment-checklist).
### Security Stack DVNS
<h4>Security Stack (DVNs)</h4>
Every application built on top of the LayerZero protocol can configure a unique messaging channel.

Multiple DVNs allows each application to configure a unique security threshold for each source and destination, known as X-of-Y-of-N.

Each DVN independently verifies the payloadHash of each message to ensure integrity. Once the designated DVN threshold has been reached, the message nonce can be marked as verified and inserted into the destination Endpoint for execution.

Each DVN applies its own verification method to check that the payloadHash is correct. Once the required DVNs and optionally a sufficient number of optional DVNs have confirmed the payloadHash, any authorized caller (for example, an Executor) can commit the message nonce into the destination Endpoint’s messaging channel for execution.

| Message Nonce | Description |
|---------------|-------------|
| 1 | The Security Stack has verified the payloadHash and the nonce has been committed to the Endpoint's messaging channel. |
| 2 | All configured DVNs have verified the payloadHash, but no caller has yet committed the nonce to the Endpoint's messaging channel. |
| 3 | Two required and one optional DVN have verified the payloadHash, meeting the security threshold, but the nonce has not yet been committed. |
| 4 | Even though the optional DVN threshold is met, the Security Stack requires that every required DVN (e.g. DVNᴬ) must verify the payloadHash before the nonce can be committed. |
| 5 | Only the required DVNs (e.g. DVNᴬ, DVNᴮ) have verified the payloadHash; none of the optional verifiers have submitted their proof. |
| 6 | Both the required DVNs and the optional threshold have verified the payloadHash, but no caller has committed the nonce to the Endpoint's messaging channel yet. |

<h4>Verification Model</h4>
Each DVN can use its own verification method to confirm that the payloadHash correctly represents the message contents. This design allows application owners to tailor their Security Stack based on the desired security level and cost–efficiency tradeoffs. For an extensive list of DVNs available for integration, see DVN Addresses.

<h4>DVN Adapters</h4>
DVN Adapters enable the integration of third-party generic message passing networks, such as native asset bridges, middlechains, or other specialized verification systems. With DVN Adapters, applications can incorporate diverse security models into their Security Stack, broadening the spectrum of available configurations while still ensuring a consistent verification interface via the payloadHash.

Since “DVN” broadly describes any verification mechanism that securely delivers a message’s payloadHash to the destination Message Library, application owners have the flexibility to integrate with virtually any infrastructure that meets their security requirements.

<h4>Configuring the Security Stack</h4>
Every LayerZero Endpoint can be used to send and receive messages. Because of that, each Endpoint has a separate Send and Receive Configuration, which an OApp can configure per remote Endpoint (i.e., the messaging channel, sending to that remote chain, receiving from that remote chain).

For a configuration to be considered valid, the Send Library configurations on Chain A must match the Receive Library configurations on Chain B.

<h4>Default Configuration</h4>
For each new channel, LayerZero provides a placeholder configutation known as the default. If you provide no configuration settings, the protocol will fallback to the default configuration.

This default configuration can vary per channel, changing the placeholder block confirmations, the X‑of‑Y‑of‑N thresholds for verification, the Executor, and the message libraries.

A default pathway configuration will typically have one of the following preset Security Stack configurations within SendULN302 and ReceiveUlN302:

| Security Stack | DVNs | Executor |
|---------------|------|----------|
| Default Send and Receive A | requiredDVNs: [ Google Cloud, LayerZero Labs ] | LayerZero Labs |
| Default Send and Receive B | requiredDVNs: [ Polyhedra, LayerZero Labs ] | LayerZero Labs |
| Default Send and Receive C | requiredDVNs: [ Dead DVN, LayerZero Labs ] | LayerZero Labs |


### Message Execution Options
<h4>Message Options</h4>
In the LayerZero protocol, message options are a way for applications to describe how they want their messages to be handled by off-chain infrastructure. These options are passed along with every message sent through LayerZero and are formatted as serialized bytes; a universal language that both the protocol and workers can understand.

Each option acts like an instruction or a setting for a specific worker. For example, you might request that a certain amount of gas / compute units are allocated to execute your message on the destination chain, or that some native tokens be delivered along with the message.

Options are how applications communicate verification and execution preferences to the off-chain workers that carry out cross-chain messages.

<h4>How Does LayerZero Route Options?</h4>
When an application sends a message through LayerZero, it includes a field called options. This field is a compact, structured byte array that can contain multiple worker-specific instructions. LayerZero doesn’t interpret these options directly; instead, it forwards them to the appropriate service providers (called workers) that know how to read and act on the instructions.

- The workers typically fall into two categories:

  - Decentralized Verifier Networks (DVNs): These provide verification to ensure the message is valid and has not been tampered with.

  - Executors: These are responsible for delivering and executing the message on the destination chain.

 The LayerZero messaging library understands how to break apart the options and route them to the correct workers. Since applications can configure message libraries, this design is modular, as new types of workers and options can be added over time without changing the core protocol.

<h4>Enforcing Options</h4>
Some applications may require strict guarantees on how their messages are handled. Without this enforcement, users could accidentally (or maliciously) send messages that fail to execute, leading to a poor user experience or even stuck tokens.

To prevent this, applications can enforce options. Enforcement means the application itself verifies and guarantees that a specific set of options is always present and correctly formatted before the message is allowed to be sent.

- Enforced options helps by:

  - Preventing underfunded executions that would otherwise fail on the destination chain.

  - Protecting users who omit critical options for a specific application use case.

  - Providing a consistent baseline experience regardless of the sender’s intent.

This concept is especially important in applications like token bridges, composable smart contracts, or stateful protocols where execution must be predictable and reliable.

<h4>Why would a user want to add extra options?</h4>
Take the example of an Omnichain Token (OFT) that supports Omnichain Composability; allowing the token to trigger additional logic after being received. This logic might involve calling another contract, performing swaps, or interacting with a dApp on the destination chain.

- In this case, the user might want to pay for:

  - A required amount of gas to ensure lzReceive() succeeds (enforced by the app).

  - Extra gas to support additional post-processing via lzCompose() (added by the user).

By adding these extra options, users pay to extend the functionality without modifying the underlying application logic.

<h4>Why Do Options Matter?</h4>
  When sending a cross-chain message, the source chain has no direct knowledge of the destination chain’s state: things like how much gas is needed, what the native currency is, or how the contract should be called.

  Options solve this by letting the sender provide detailed instructions about how the message should be processed once it arrives.

  - Some common examples include:

    - Execution Gas: Telling the Executor how much gas or native token the destination contract will need during lzReceive().

    - Composer Gas: Adding gas or native tokens for the composer contract when calling calling lzCompose().

    - Native Token Drops: Sending native tokens (like ETH or APT) separately from the message.

These instructions are interpreted by the off-chain workers, so that the message is handled as expected.


- Key Takeaways
  - options are serialized instructions that help off-chain workers understand how to process a message.

  - Each type of worker (DVN, Executor, etc.) looks for specific options relevant to their task.

  - Applications can enforce options to require correct behavior on source.

  - Users can extend options for extra functionality on destination.

  - The LayerZero protocol’s modular design means it can support new worker types without breaking existing behavior.

<div style="background-color: #99a0a5ff; border-left: 4px solid #007acc; padding: 10px; margin: 10px 0;">

**Info:** Enforcing options means your application checks that users provide the correct options when calling the Endpoint's `send()` method. However, this does NOT guarantee that the specified instructions (e.g., gas limits or native drops) will be executed as intended by the worker or respected by permissionless callers on the destination chain.

If your application requires strict guarantees, such as an exact gas amount or mandatory native gas drops, you must also validate those conditions on-chain at the destination, or use a worker you trust. See the Integration Checklist for guidance on how to enforce execution requirements inside your `_lzReceive()` or `lzCompose()` logic.
</div>

### Generating Options 
Generating Options is possible using typescript or solidity as follows: 

  ```typescript 
  import {Options} from '@layerzerolabs/lz-v2-utilities';

  const options = Options.newOptions().addExecutorLzReceiveOption(gas_limit, msg_value).toBytes();
  ```

  ```solidity
  using OptionsBuilder for bytes;

  bytes memory options = OptionsBuilder.newOptions()
    .addExecutorLzReceiveOption(50000, 0)
    .toBytes();
  ```

<div style="background-color: #99a0a5ff; border-left: 4px solid #007acc; padding: 10px; margin: 10px 0;">

**Caution:** Since the return data size is not known to the Executor ahead of time, you must estimate the expected response data size. This size is priced into the Executor's fee formula. Failure to correctly estimate the return data size will result in the Executor not delivering the response.

</div>

- Best Practices
  - Gas Profiling: Always profile your contract's gas usage on each target chain
  - Conservative Estimates: Start with higher gas limits and adjust down
  - Chain-Specific Testing: Test thoroughly on each target chain
  - Native Caps: Check Executor's native cap for each pathway
  - Multiple Options: Consider combining options for complex scenarios

See the [OptionsBuilder](https://docs.layerzero.network/v2/tools/sdks/options) library and SDK to learn more about the specific encoding of options.

## Production Deployment Checklist

Before deploying, ensure the following:

- (recommended) you have profiled the gas usage of `lzReceive` on your destination chains
- (recommended) you have configured appropriate DVNs for your security requirements
- (recommended) you have tested your application thoroughly on testnets

<p align="center">
  Join our <a href="https://layerzero.network/community" style="color: #a77dff">community</a>! | Follow us on <a href="https://x.com/LayerZero_Labs" style="color: #a77dff">X (formerly Twitter)</a>
</p>

# Appendix

## Running Tests

Similar to the contract compilation, we support both `hardhat` and `forge` tests. By default, the `test` command will execute both:

```bash
pnpm test
```

If you prefer one over the other, you can use the tooling-specific commands:

```bash
pnpm test:forge
pnpm test:hardhat
```

## Adding other chains

If you're adding another EVM chain, first, add it to the `hardhat.config.ts`. Adding non-EVM chains do not require modifying the `hardhat.config.ts`.

Then, modify `layerzero.config.ts` with the following changes:

- declare a new contract object (specifying the `eid` and `contractName`)
- decide whether to use an existing EVM enforced options variable or declare a new one
- create a new entry in the `connections` array
- add the new contract into the `contracts` array of the `export default` function

After applying the desired changes, make sure you re-run the wiring task:

```bash
pnpm hardhat lz:oapp:wire --oapp-config layerzero.config.ts
```

## Using Multisigs

The wiring task supports the usage of Safe Multisigs.

To use a Safe multisig as the signer for these transactions, add the following to each network in your `hardhat.config.ts` and add the `--safe` flag to `lz:oapp:wire --safe`:

```typescript
// hardhat.config.ts

networks: {
  // Include configurations for other networks as needed
  fuji: {
    /* ... */
    // Network-specific settings
    safeConfig: {
      safeUrl: 'http://something', // URL of the Safe API, not the Safe itself
      safeAddress: 'address'
    }
  }
}
```

## LayerZero Hardhat Helper Tasks

LayerZero Devtools provides several helper hardhat tasks to easily deploy, verify, configure, connect, and interact with OApps cross-chain.

<details>
<summary> <a href="https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/deploying"><code>pnpm hardhat lz:deploy</code></a> </summary>

 <br>

Deploys your contract to any of the available networks in your [`hardhat.config.ts`](./hardhat.config.ts) when given a deploy tag (by default contract name) and returns a list of available networks to select for the deployment. For specifics around all deployment options, please refer to the [Deploying Contracts](https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/deploying) section of the documentation. LayerZero's `lz:deploy` utilizes `hardhat-deploy`.

More information about available CLI arguments can be found using the `--help` flag:

```bash
pnpm hardhat lz:deploy --help
```

</details>

<details>
<summary> <a href="https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/start"><code>pnpm hardhat lz:oapp:config:init --oapp-config YOUR_OAPP_CONFIG --contract-name CONTRACT_NAME</code></a> </summary>

 <br>

Initializes a `layerzero.config.ts` file for all available pathways between your hardhat networks with the current LayerZero default placeholder settings. This task can be incredibly useful for correctly formatting your config file.

You can run this task by providing the `contract-name` you want to set for the config and `file-name` you want to generate:

```bash
pnpm hardhat lz:oapp:config:init --contract-name CONTRACT_NAME --oapp-config FILE_NAME
```

</details>

<details>
<summary> <a href="https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/wiring"><code>pnpm hardhat lz:oapp:config:wire --oapp-config YOUR_OAPP_CONFIG</code></a> </summary>

 <br>

Calls the configuration functions between your deployed OApp contracts on every chain based on the provided `layerzero.config.ts`.

Running `lz:oapp:wire` will make the following function calls per pathway connection for a fully defined config file using your specified settings and your environment variables (Private Keys and RPCs):

- <a href="https://github.com/LayerZero-Labs/LayerZero-v2/blob/main/packages/layerzero-v2/evm/oapp/contracts/oapp/OAppCore.sol#L33-L46"><code>function setPeer(uint32 \_eid, bytes32 \_peer) public virtual onlyOwner {}</code></a>

- <a href="https://github.com/LayerZero-Labs/LayerZero-v2/blob/main/packages/layerzero-v2/evm/protocol/contracts/MessageLibManager.sol#L304-L311"><code>function setConfig(address \_oapp, address \_lib, SetConfigParam[] calldata \_params) external onlyRegistered(\_lib) {}</code></a>

- <a href="https://github.com/LayerZero-Labs/LayerZero-v2/blob/main/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OAppOptionsType3.sol#L18-L36"><code>function setEnforcedOptions(EnforcedOptionParam[] calldata \_enforcedOptions) public virtual onlyOwner {}</code></a>

- <a href="https://github.com/LayerZero-Labs/LayerZero-v2/blob/main/packages/layerzero-v2/evm/protocol/contracts/MessageLibManager.sol#L223-L238"><code>function setSendLibrary(address \_oapp, uint32 \_eid, address \_newLib) external onlyRegisteredOrDefault(\_newLib) onlySupportedEid(\_newLib, \_eid) {}</code></a>

- <a href="https://github.com/LayerZero-Labs/LayerZero-v2/blob/main/packages/layerzero-v2/evm/protocol/contracts/MessageLibManager.sol#L223-L273"><code>function setReceiveLibrary(address \_oapp, uint32 \_eid, address \_newLib, uint256 \_gracePeriod) external onlyRegisteredOrDefault(\_newLib) isReceiveLib(\_newLib) onlySupportedEid(\_newLib, \_eid) {}</code></a>

To use this task, run:

```bash
pnpm hardhat lz:oapp:wire --oapp-config YOUR_LAYERZERO_CONFIG_FILE
```

Whenever you make changes to the configuration, run `lz:oapp:wire` again. The task will check your current configuration, and only apply NEW changes.

</details>

<details>
<summary> <a href="https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/wiring#checking-pathway-config"><code>pnpm hardhat lz:oapp:config:get --oapp-config YOUR_OAPP_CONFIG</code></a> </summary>

 <br>

Returns your current OApp's configuration for each chain and pathway in 3 columns:

- **Custom Configuration**: the changes that your `layerzero.config.ts` currently has set

- **Default Configuration**: the default placeholder configuration that LayerZero provides

- **Active Configuration**: the active configuration that applies to the message pathway (Defaults + Custom Values)

If you do NOT explicitly set each configuration parameter, your OApp will fallback to the placeholder parameters in the default config.

</details>

## Contract Verification

You can verify EVM chain contracts using the LayerZero helper package:

```bash
pnpm dlx @layerzerolabs/verify-contract -n <NETWORK_NAME> -u <API_URL> -k <API_KEY> --contracts <CONTRACT_NAME>
```

## Troubleshooting

### Debugging Messages
The V2 protocol now splits the verification and contract logic execution of messages into two separate, distinct phases:

`Verified:` the destination chain has received verification from all configured DVNs and the message nonce has been committed to the Endpoint's messaging channel.

`Delivered:` the message has been successfully executed by the Executor.

Because verification and execution are separate, LayerZero can provide specific error handling for each message state.

General debugging steps can be found [here](https://docs.layerzero.network/v2/concepts/troubleshooting/debugging-messages).

#### Message Execution
When your message is successfully delivered to the destination chain, the protocol attempts to execute the message with the execution parameters defined by the sender. Message execution can result in two possible states:

`Success:` If the execution is successful, an event (PacketReceived) is emitted.

`Failure:` If the execution fails, the contract reverses the clearing of the payload (re-inserts the payload) and emits an event (LzReceiveAlert) to signal the failure.

  - Out of Gas: The message fails because the transaction that contains the message doesn't provide enough gas for execution.

  - The Message Execution Options applied to a message can be viewed on LayerZero Scan. There are several ways to determine the optimal gas values for these options. See Determining Gas Costs for more details.

  - Logic Error: There's an error in either the contract code or the message parameters passed that prevents the message from being executed correctly.

More information on debugging can be found [here](https://docs.layerzero.network/v2/developers/evm/troubleshooting/debugging-messages). 


### Error Codes & Handling

(https://docs.layerzero.network/v2/developers/evm/troubleshooting/error-messages).

---

<p align="center">
  Happy building with LayerZero!
</p>
