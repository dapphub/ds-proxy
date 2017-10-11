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

contract DSProxyCache {
    mapping( bytes32 => address ) public cache;
    function read(bytes32 hash) public returns (address);
    function read(bytes code) public view returns (address);
    function write(bytes _code, address _target) public returns (bool);
}

// DSProxy
// Allows code execution using a persistant identity This can be very
// useful to execute a sequence of atomic actions. Since the owner of
// the proxy can be changed, this allows for dynamic ownership models
// i.e. a multisig
contract DSProxy is DSAuth, DSNote {
    DSProxyCache   public cache;    // global cache for code -> canonical address
    bool           public system; // prevents proxy owner from butchering the cache

    function DSProxy() public {
        // Proxies should only be deployed via the factory or else they will malfunction
        cache = DSProxyCache(msg.sender);
    }

    function() public payable {
    }

    function exec() {
        // TODO aliases
    }

    // use the proxy to execute calldata `data` on contract `code`
    function execute(bytes code, bytes data)
        public
        auth
        note
        payable
        returns (bytes32 response)
    {
        address target;

        // deploy contract if uncached
        target = cache.read(code);
        if (target == 0x0) {
            system = true;
            assembly {
                target := create(0, add(code, 0x20), mload(code))
                switch iszero(extcodesize(target))
                case 1 {
                    // throw if contract failed to deploy
                    revert(0, 0)
                }
            }
            // store deployed contract address in cache
            cache.write(code, target);
            system = false;
        }

        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas, 5000), target, add(data, 0x20), mload(data), 0, 32)
            response := mload(0)      // load delegatecall output
            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(0, 0)
            }
        }
        return response;
    }
}

// DSProxyFactory
// This factory deploys new proxy instances through build()
// Deployed proxy addresses are logged
// 
contract DSProxyFactory is DSProxyCache {
    event Created(address indexed sender, address proxy);
    mapping(address=>bool) public isProxy;

    //deploys a new proxy instance
    //sets owner of proxy to caller
    function build() public returns (DSProxy) {
        DSProxy proxy = new DSProxy();
        Created(msg.sender, address(proxy));
        proxy.setOwner(msg.sender);
        isProxy[proxy] = true;
        return proxy;
    }


    function read(bytes code)
        public view returns (address) {
        bytes32 hash = keccak256(code);
        return cache[hash];
    }
    function read(bytes32 hash) public returns (address) {
        return cache[hash];
    }

    function write(bytes _code, address _target)
        public
        returns (bool)
    {
        require(isProxy[msg.sender]);
        require(DSProxy(msg.sender).system());
        bytes32 hash = keccak256(_code);
        if (_target == 0x0) {
            // invalid contract
            revert();
        }
        cache[hash] = _target;
        return true;
    }

}
