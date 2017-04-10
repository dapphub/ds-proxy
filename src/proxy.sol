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
import "Ds-note/note.sol";

contract DSProxy is DSAuth, DSNote {
	function execute(bytes _code, bytes _data)
		auth
		note
		payable
		returns (bytes32 response)
	{
		assembly {
			let target := create(0, add(_code, 0x20), mload(_code))	//deploy contract
			jumpi(invalidJumpLabel, iszero(extcodesize(target)))    //throw if deployed contract contains code
			let succeeded := delegatecall(sub(gas, 5000), target, add(_data, 0x20), mload(_data), response, 32) //call deployed contract in current context
			jumpi(invalidJumpLabel, iszero(succeeded))             //throw if delegatecall failed
		}
		return response;
	}
}
contract DSProxyFactory {
	event Created(address sender, address proxy);
	mapping(address=>bool) public isProxy;
    function build() returns (DSProxy) {
        var proxy = new DSProxy();			//create new proxy contract
        Created(msg.sender, proxy);			//trigger Created event
        proxy.setAuthority(msg.sender);			//set authority of proxy
        isProxy[proxy] = true;				//log proxys created by this factory
        return proxy;
    }
}