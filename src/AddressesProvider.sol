pragma solidity 0.8.21;

import {Ownable} from '@openzeppelin/access/Ownable.sol';
import {ERC1967Proxy} from '@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol';
import {ERC1967Utils} from '@openzeppelin/proxy/ERC1967/ERC1967Utils.sol';
import {IUpgradeableToken} from './interfaces/IUpgradeableToken.sol';

contract AddressesProvider is Ownable(msg.sender) {

  using ERC1967Utils for ERC1967Proxy;
  // Map of registered addresses (identifier => registeredAddress)
  mapping(bytes32 => address) private _addresses;

  // Main identifiers
  bytes32 private constant TOKEN = 'wstBTC';


event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed newImplementationAddress
  );

  event TokenUpdated(address indexed newAddress);


  constructor(address owner) {
    transferOwnership(owner);
  }

  function getAddress(bytes32 id) public view returns (address) {
    return _addresses[id];
  }

  function setAddress(bytes32 id, address newAddress) external onlyOwner {
    address oldAddress = _addresses[id];
    _addresses[id] = newAddress;
    emit AddressSet(id, oldAddress, newAddress);
  }

  function setAddressAsProxy(
    bytes32 id,
    address newImplementationAddress
  ) external onlyOwner {
    address proxyAddress = _addresses[id];
    _updateImpl(id, newImplementationAddress);
    emit AddressSetAsProxy(id, proxyAddress, newImplementationAddress);
  }
  
  function setTokenImpl(address newTokenImpl) external onlyOwner {
    _updateImpl(TOKEN, newTokenImpl);
    emit TokenUpdated(newTokenImpl);
  }

    function getToken() external view returns (address) {
    return getAddress(TOKEN);
  }


  function updateAggregator(address newAggregator) external onlyOwner {
    IUpgradeableToken(getAddress(TOKEN)).updateAggregator(newAggregator);
  }

  /**
   * @notice Internal function to update the implementation of a specific proxied component of the protocol.
   * @dev If there is no proxy registered with the given identifier, it creates the proxy setting `newAddress`
   *   as implementation and calls the initialize() function on the proxy
   * @dev If there is already a proxy registered, it just updates the implementation to `newAddress` and
   *   calls the initialize() function via upgradeToAndCall() in the proxy
   * @param id The id of the proxy to be updated
   * @param newAddress The address of the new implementation
   */
  function _updateImpl(bytes32 id, address newAddress) internal {
    address proxyAddress = _addresses[id];
    // initialize with the address provider
    bytes memory params = abi.encodeWithSignature('initialize(address)', address(this));

    if (proxyAddress == address(0)) {
      address proxy = address(new ERC1967Proxy(newAddress, params));
      _addresses[id] = proxyAddress = proxy;
      emit ProxyCreated(id, proxyAddress, newAddress);
    } else {
      IUpgradeableToken(proxyAddress).upgradeToAndCall(newAddress, params);
    }
  }

}
