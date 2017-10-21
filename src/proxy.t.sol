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

import "ds-test/test.sol";
import "./proxy.sol";

contract DSProxyTest is DSTest {
	DSProxyFactory factory;
	DSProxyCache cache;
	DSProxy proxy;

	function setUp() public {
		factory = new DSProxyFactory();
		cache = new DSProxyCache();
		proxy = new DSProxy(cache);
	}

	///test1 - check that DSProxyFactory creates a cache
	function test_DSProxyFactoryCheckCache() public {
		assertTrue(address(factory.cache) > 0x0);
	}

	///test 2 - build a proxy from DSProxyFactory and verify logging
	function test_DSProxyFactoryBuildProc() public {
		address proxyAddr = factory.build();
		assertTrue(proxyAddr > 0x0);
		proxy = DSProxy(proxyAddr);

		uint codeSize;
		assembly {
			codeSize := extcodesize(proxyAddr)
		}
		//verify proxy was deployed successfully
		assertTrue(codeSize > 0);

		//verify proxy creation was logged
		assertTrue(factory.isProxy(proxyAddr));

		//verify logging doesnt return false positives
		address notProxy = 0xd2A49A27F3E68d9ab1973849eaA0BEC41A6592Ed;
		assertTrue(!factory.isProxy(notProxy));
	}

	///test 3 - verify getting a cache
	function test_DSProxyCacheAddr1() public {
		DSProxy p = new DSProxy(cache);
		assertTrue(address(p) > 0x0);
		address cacheAddr = p.cache();
		assertTrue(cacheAddr == address(cache));
		assertTrue(cacheAddr != 0x0);
	}

	///test 4 - verify setting a new cache
	function test_DSProxyCacheAddr2() public {
		DSProxy p = new DSProxy(cache);
		assertTrue(address(p) > 0x0);
		address newCacheAddr = address(new DSProxyCache());
		address oldCacheAddr = address(cache);
		assertEq(p.cache(), oldCacheAddr);
		assertTrue(p.setCache(newCacheAddr));
		assertEq(p.cache(), newCacheAddr);
		assertTrue(oldCacheAddr != newCacheAddr);
	}

	//Test Contract Used
	//bytecode = 0x60606040523415600b57fe5b5b609e8061001a6000396000f30060606040526000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680630bcd3b3314603a575bfe5b3415604157fe5b60476065565b60405180826000191660001916815260200191505060405180910390f35b6000600160010290505b905600a165627a7a72305820c0a9ddff06dd48d3745191e58e1c0cb32c940886d299b285a91fdaa5884551560029
	/*
	pragma solidity ^0.4.9;
	contract Mini {
		function getBytes() returns (bytes32) {
			return bytes32(0x1);
		}
	}
	*/

	///test 5 - execute an action through proxy and verify caching
	function test_DSProxyExecute() public {
		//test contract bytecode
		bytes memory testCode = hex"60606040523415600b57fe5b5b609e8061001a6000396000f30060606040526000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680630bcd3b3314603a575bfe5b3415604157fe5b60476065565b60405180826000191660001916815260200191505060405180910390f35b6000600160010290505b905600a165627a7a72305820c0a9ddff06dd48d3745191e58e1c0cb32c940886d299b285a91fdaa5884551560029";
		
		//function identifier for getBytes()(bytes32)
		bytes memory calldata = hex"0bcd3b33";

		//verify contract is not stored in cache
		assertEq(cache.read(testCode), 0x0);

		//deploy and call the contracts code
		var (target, response) = proxy.execute(testCode, calldata);

		//verify we got correct response
		assertEq(response, bytes32(0x1));

		//verify contract is stored in cache
		assertTrue(cache.read(testCode) != 0x0);

		//call the contracts code using target address
 		response = proxy.execute(target, calldata);
 
 		//verify we got correct response
 		assertEq(response, bytes32(0x1));
	}

	///test 6 - proxy receives ETH
	function test_DSProxyReceiveETH() public {
		assertEq(proxy.balance, 0);
		assert(proxy.call.value(10)());
		assertEq(proxy.balance, 10);
	}
}
