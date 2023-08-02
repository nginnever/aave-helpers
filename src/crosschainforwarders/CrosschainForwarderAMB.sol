// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IL2BridgeExecutor} from 'governance-crosschain-bridges/contracts/interfaces/IL2BridgeExecutor.sol';

interface IAMB {
  function requireToPassMessage(
    address _contract,
    bytes memory _data,
    uint256 _gas
  ) external returns (bytes32);
}

/**
 * @title A generic executor for proposals targeting the gnosis chain v3 pool
 * @author Gnosis Guild
 * @notice You can **only** use this executor when the AMB payload has a `execute()` signature without parameters
 * @notice You can **only** use this executor when the AMB payload is expected to be executed via `DELEGATECALL`
 * @notice You can **only** execute payloads on Gnosis Chain with up to prepayed gas which is specified in `enqueueL2GasPrepaid` gas.
 * Prepaid gas is the maximum gas covered by the bridge without additional payment.
 * @dev This executor is a generic wrapper to be used with Optimism CrossDomainMessenger (https://etherscan.io/address/0x4C36d2919e407f0Cc2Ee3c993ccF8ac26d9CE64e)
 * It encodes and sends via the L2CrossDomainMessenger a message to queue for execution an action on Gnosis Chain, in the Aave AMB_BRIDGE_EXECUTOR.
 */
contract CrosschainForwarderAMB {
  /**
   * @dev The L1 Cross Domain Messenger contract sends messages from L1 to L2, and relays messages
   * from L2 onto L1. In this contract it's used by the governance SHORT_EXECUTOR to send the encoded L2 queuing over the bridge.
   */
  address public constant L1_AMB_CROSS_DOMAIN_MESSENGER_ADDRESS =
    0x4C36d2919e407f0Cc2Ee3c993ccF8ac26d9CE64e;

  /**
   * @dev The Gnosis Chain bridge executor is a sidechain governance execution contract.
   * This contract allows queuing of proposals by allow listed addresses (in this case the L1 short executor).
   * https://gnosisscan.io/address/0x75Df5AF045d91108662D8080fD1FEFAd6aA0bb59
   */
  address public constant AMB_BRIDGE_EXECUTOR = 0x75Df5AF045d91108662D8080fD1FEFAd6aA0bb59;

  /**
   * @dev The gas limit of the queue transaction by the L2CrossDomainMessenger on Gnosis Chain.
   */
  uint256 public constant MAX_GAS_LIMIT = 5_000_000;

  /**
   * @dev this function will be executed once the proposal passes the mainnet vote.
   * @param l2PayloadContract the Gnosis Chain contract containing the `execute()` signature.
   */
  function execute(address l2PayloadContract) public {
    address[] memory targets = new address[](1);
    targets[0] = l2PayloadContract;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    string[] memory signatures = new string[](1);
    signatures[0] = 'execute()';
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = '';
    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = true;

    bytes memory queue = abi.encodeWithSelector(
      IL2BridgeExecutor.queue.selector,
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls
    );

    IAMB(L1_AMB_CROSS_DOMAIN_MESSENGER_ADDRESS).requireToPassMessage(
      AMB_BRIDGE_EXECUTOR,
      queue,
      MAX_GAS_LIMIT
    );
  }
}