/*
   Copyright 2016-2017 DappHub, LLC

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
pragma solidity ^0.4.13;

import "ds-auth/auth.sol";
import "ds-note/note.sol";

//DSProxy
//Allows code execution using a persistant identity
//This can be very useful to execute a sequence of
//atomic actions. Since the owner of the proxy can
//be changed, this allows for dynamic ownership models
//i.e. a multisig
contract DSProxy is DSAuth, DSNote { 
  DSProxyCache public cache;                                  //global cache for contracts

  function DSProxy(address _cacheAddr) public {
    assert(setCache(_cacheAddr));
  }

  function() public payable {
  }

  //use the proxy to execute calldata _data on contract _code
  function execute(bytes _code, bytes _data)
    public
    auth
    note
    payable
    returns (bytes32 response)
  {
    address target;

    target = cache.read(_code);                         //check if contract is cached
    if (target == 0x0) {
      assembly {                                              //contract is not cached
        target := create(0, add(_code, 0x20), mload(_code))   //deploy contract
        switch iszero(extcodesize(target))                    //throw if deployed contract is empty
        case 1 {
          revert(0, 0)                                        //contract failed to deploy => throw
        }
      }
      cache.write(_code, target);                             //store deployed contract address in cache
    }

    assembly {                                                //call contract in current context
      let succeeded := delegatecall(sub(gas, 5000), target, add(_data, 0x20), mload(_data), 0, 32)
      response := mload(0)                                    //load delegatecall output to response
      switch iszero(succeeded)                                //throw if delegatecall failed
      case 1 {
        revert(0, 0)                                          //delegatecall failed => throw
      }
    }
    return response;
  }

  //set new cache
  function setCache(address _cacheAddr)
    public
    auth
    note
    returns (bool) 
  {
    if (_cacheAddr == 0x0) revert();                          //invalid cache address
    cache = DSProxyCache(_cacheAddr);                         //overwrite cache
    return true;
  }

  //get current cache
  function getCache() public view returns (address) {
    return cache;
  }
}

//DSProxyFactory
//This factory deploys new proxy instances through build()
//Deployed proxy addresses are logged 
contract DSProxyFactory {
  event Created(address indexed sender, address proxy, address cache);
  mapping(address=>bool) public isProxy;
  DSProxyCache public cache = new DSProxyCache();
  
  //deploys a new proxy instance
  //sets owner of proxy to caller
  function build() public returns (DSProxy) {
    DSProxy proxy = new DSProxy(cache);                       //create new proxy contract
    Created(msg.sender, address(proxy), address(cache));      //trigger Created event
    proxy.setOwner(msg.sender);                               //set caller as owner of proxy
    isProxy[proxy] = true;                                    //log proxys created by this factory
    return proxy;
  }
}

//DSProxyCache
//This global cache stores addresses of contracts previously
//deployed by a proxy. This saves gas from repeat deployment of
//the same contracts and eliminates blockchain bloat.
//By default, all proxies deployed from the same factory store contracts
//in the same cache. The cache a proxy instance uses can be changed.
//The cache uses the sha3 hash of a contracts bytecode to lookup the address
contract DSProxyCache {
  mapping(bytes32 => address) cache;

  //check if cache contains contract
  function read(bytes _code) public view returns (address) {
    bytes32 hash = keccak256(_code);
    return cache[hash];
  }

  //write new contract to cache
  function write(bytes _code, address _target) public returns (bool) {
    bytes32 hash = keccak256(_code);                               //get keccak-256 hash of contract code
    if (_target == 0x0) {
      revert();                                               //invalid contract
    }
    cache[hash] = _target;                                    //map contract hash to contract address
    return true;
  }
}
