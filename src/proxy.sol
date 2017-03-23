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
//Check that gas is ok to use as a RAW value inside create (may need some masking/casting)
//Ask if we want Zeppelin and uPort integration compatibility
//Do we want a DSProxyFactory contract to initialize and return DSProxy? Do we want an event Created() when the factory produces a proxy?

//CONSTRAINTS
//contract should not expect an endowment in their constructor.


pragma solidity ^0.4.9;

import "ds-auth/auth.sol";

contract DSProxyEvents {
	event Forwarded(address indexed target, uint value, bytes calldata);
}

contract DSProxy is DSProxyEvents, DSAuth {
	function execute(bytes _code, bytes _data)
		auth
		payable
		returns (bytes32 response)
	{
		uint256 codeLength = _code.length;
		uint256 dataLength = _data.length;

		address target;
		bool succeeded = false;
		
		assembly {
			let pMem := mload(0x40)                 //load free memory pointer
			calldatacopy(pMem, _code, codeLength)   //copy contract code from calldata to memory
			target := create(0, pMem, codeLength) //deploy contract
			jumpi(0x02, izero(target))              //verify address of deployed contract
			calldatacopy(pMem, _data, dataLength)   //copy request data from calldata to memory
			succeeded := delegatecall(gas, target, pMem, dataLength, pMem, 32) //call deployed contract
			jumpi(0x02, iszero(succeeded))          //throw if delegatecall failed
			response := mload(pMem)                 //set delegatecall output to response
		}
		Forwarded(target, msg.value, _data);        //trigger event log
		return response;
	}
}