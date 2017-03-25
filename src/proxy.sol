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

//NOTES
//Is the proxy contract supposed to re-throw on exception, or report it as "executed"?

//I would like to see a way to forward an arbitrary number of transactions in order.
//This is important from a UX perspective, so dapp developers can make "all or nothing" transactions which are dependent on each other.
//function forward_transactions (address[] _destinations, uint[] _values, bytes[] _bytecodes) {}

pragma solidity ^0.4.9;

import "ds-auth/auth.sol";
import "ds-note/note.sol";

contract DSProxy is DSAuth, DSNote {
	function execute(bytes _code, bytes _data)
		auth
		note
		payable
		returns (bytes32 response)
	{	
		uint256 codeLength = _code.length;
		uint256 dataLength = _data.length;
		
		assembly {
			let pMem := mload(0x40)                     //load free memory pointer
			calldatacopy(pMem, _code, codeLength)       //copy contract code from calldata to memory
			let target := create(0, pMem, codeLength)   //deploy contract
			jumpi(0x02, iszero(target))                 //verify address of deployed contract
			calldatacopy(pMem, _data, dataLength)       //copy request data from calldata to memory
			let succeeded := delegatecall(gas, target, pMem, dataLength, pMem, 32) //call deployed contract
			jumpi(0x02, iszero(succeeded))              //throw if delegatecall failed
			response := mload(pMem)                     //set delegatecall output to response
		}
		return response;
	}
}

contract DSProxyFactory {
	event Created(address sender, address proxy);

	mapping(address=>bool) public isProxy;

    function build() returns (DSProxy) {
        var proxy = new DSProxy();
        Created(msg.sender, proxy);
        proxy.setAuthority(msg.sender);
        isProxy[proxy] = true;
        return proxy;
    }
}