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
pragma solidity ^0.4.9;

import "ds-auth/auth.sol";
import "ds-note/note.sol";

contract DSProxy is DSAuth, DSNote { 
  address cacheAddr;                                          //address of the global proxy cache

  function execute(bytes _code, bytes _data)
  auth
  note
  payable
  returns (bytes32 response)
  {
    address target;

    //TODO:
    //what if cache address points to contract thats not a cache?
    //do you check for this in setCache() or during execute()?
    if (cacheAddr != 0x0) {                                     //check if cache has been set
      DSProxyCache cache = DSProxyCache(cacheAddr);             //use global proxy cache
      target = cache.readCache(sha3(_code));                    //check if contract is cached
    }
    if (target == 0x0) {
      assembly {                                              //contract is not cached
        target := create(0, add(_code, 0x20), mload(_code))   //deploy contract
        jumpi(invalidJumpLabel, iszero(extcodesize(target)))  //throw if deployed contract is empty
      }
      cache.writeCache(sha3(_code), target);                  //store deployed contract address in cache
    }

    assembly {
      let succeeded := delegatecall(sub(gas, 5000), target, add(_data, 0x20), mload(_data), 0, 32) //call contract in current context
      response := mload(0)		                     //load delegatecall output to response
      jumpi(invalidJumpLabel, iszero(succeeded))             //throw if delegatecall failed
		}
		return response;
	}

  function setCache(address _cacheAddr) returns (bool) {
    if (_cacheAddr == 0x0) throw;     //invalid cache address
    cacheAddr = _cacheAddr;
    return true;
  }

  function getCache() returns (address) {
    return cacheAddr;
  }
}
contract DSProxyFactory {
	event Created(address sender, address proxy);
	mapping(address=>bool) public isProxy;
    function build() returns (DSProxy) {
        var proxy = new DSProxy();			//create new proxy contract
        Created(msg.sender, proxy);			//trigger Created event
        proxy.setOwner(msg.sender);			//set caller as owner of proxy
        isProxy[proxy] = true;				//log proxys created by this factory
        return proxy;
    }
}

contract DSProxyCache {
  mapping(bytes32 => address) cache;

  function readCache(bytes32 hash) returns (address) {
    return cache[hash];
  }
  function writeCache(bytes32 hash, address target) returns (bool) {
    if (hash == 0x0 || target == 0x0) {
      throw;                            //invalid contract
    }
    cache[hash] = target;
    return true;
  }
}