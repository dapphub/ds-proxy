pragma solidity ^0.4.8;

import "ds-test/test.sol";
import "./proxy.sol";

contract DSProxyTest is DSTest {
	DSProxyFactory factory;
	DSProxy proxy;

	function setUp() {
		factory = new DSProxyFactory();
	}

	///test 1 - build a proxy from DSProxyFactory
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

	///test 2 - use proxy to getBytes from test contract - no args in calldata
	/* Due to restrictions in the EVM with how it handles hex literals this test will fail
	In order for ds-proxys execute functin to work the bytes hex data for contracts and calldata
	must originate from a JSON-RPC source and cannot be sourced from a hex literal. There can
	be middle men contracts inbetween the JSON-RPC source and the proxy. 
	function test_DSProxyExecuteProc() {
		bytes32 response;

		//test contract bytecode
		bytes memory testCode = hex"60606040523415600b57fe5b5b609e8061001a6000396000f30060606040526000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680630bcd3b3314603a575bfe5b3415604157fe5b60476065565b60405180826000191660001916815260200191505060405180910390f35b6000600160010290505b905600a165627a7a72305820cd1ba858674bd634c7ab2f54a43d025c7a9beedd22fc041d57777bb481c6a23e0029";

		//function identifier for getBytes()(bytes32)
		bytes memory calldata = hex"0bcd3b33";

		response = proxy.execute(testCode, calldata);

		assertEq(response, bytes32(0x1));
	}
	*/
}
