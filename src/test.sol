pragma solidity ^0.4.8;

import "ds-test/test.sol";
import "./proxy.sol";

contract DSProxyTest is DSTest {
	DSProxyFactory factory;
	DSProxy proxy;

	function setUp() {
		factory = new DSProxyFactory();
	}

	//test 1 - build a proxy from DSProxyFactory
	function test_DSProxyFactoryBuildProc() {
		address proxyAddr = factory.build();
		assert(proxyAddr > 0x0);
		proxy = DSProxy(proxyAddr);


		uint codeSize;
		assembly {
			codeSize := extcodesize(proxyAddr)
		}
		assert(codeSize > 0);

		assert(factory.isProxy(proxyAddr));
	}

	//test 2 - use proxy to getBytes from test contract - no args in calldata
	//Currently returns bad instruction
	//may have something to do with input not having length as first 32 bytes (check calldata in seth)
	function test_DSProxyExecuteProc() {
		//test contract bytecode
		bytes32 response;
		bytes memory testCode = hex'60606040523415600b57fe5b5b609e8061001a6000396000f30060606040526000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680630bcd3b3314603a575bfe5b3415604157fe5b60476065565b60405180826000191660001916815260200191505060';
		bytes memory calldata = hex'0bcd3b33';
		response = proxy.execute(testCode, calldata);
		//assertEq(response, 0x1);
	}

	//test 3 - use proxy to getIdentity from test contract (identity = arg)
}
