// proxy.t.sol - test for proxy.sol

// Copyright (C) 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.4.23;

import "ds-test/test.sol";
import "./proxy.sol";

// Test Contract Used
contract TestContract {
    function getBytes32() public pure returns (bytes32) {
        return bytes32("Hello");
    }
    function getBytes32AndUint() public pure returns (bytes32, uint) {
        return (bytes32("Bye"), 150);
    }
    function getMultipleValues(uint amount) public pure returns (bytes32[] result) {
        result = new bytes32[](amount);
        for (uint i = 0; i < amount; i++) {
            result[i] = bytes32(i);
        }
    }
    function get48Bytes() public pure returns (bytes result) {
        assembly {
            result := mload(0x40)
            mstore(result, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
            mstore(add(result, 0x20), "AAAAAAAAAAAAAAAA")
            return(result, 0x30)
        }
    }
    function fail() public pure returns (bytes32 result) {
        result = "Fail test case";
        require(false, "Fail test case");
    }
}

contract WithdrawFunds {
    function withdraw(uint256 amount) public {
        msg.sender.transfer(amount);
    }
}

contract DSProxyTest is DSTest {
    DSProxyFactory factory;
    DSProxyCache cache;
    DSProxy proxy;

    bytes testCode = hex"608060405234801561001057600080fd5b5061041c806100206000396000f30060806040526004361061006d576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680631f903037146100725780635f7a3d16146100a55780638583cc0b14610127578063a9cc471814610161578063aa4025cc14610194575b600080fd5b34801561007e57600080fd5b50610087610224565b60405180826000191660001916815260200191505060405180910390f35b3480156100b157600080fd5b506100d06004803603810190808035906020019092919050505061024c565b6040518080602001828103825283818151815260200191508051906020019060200280838360005b838110156101135780820151818401526020810190506100f8565b505050509050019250505060405180910390f35b34801561013357600080fd5b5061013c6102cc565b6040518083600019166000191681526020018281526020019250505060405180910390f35b34801561016d57600080fd5b506101766102fd565b60405180826000191660001916815260200191505060405180910390f35b3480156101a057600080fd5b506101a961039b565b6040518080602001828103825283818151815260200191508051906020019080838360005b838110156101e95780820151818401526020810190506101ce565b50505050905090810190601f1680156102165780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b60007f48656c6c6f000000000000000000000000000000000000000000000000000000905090565b606060008260405190808252806020026020018201604052801561027f5781602001602082028038833980820191505090505b509150600090505b828110156102c6578060010282828151811015156102a157fe5b9060200190602002019060001916908160001916815250508080600101915050610287565b50919050565b6000807f42796500000000000000000000000000000000000000000000000000000000006096809050915091509091565b60007f4661696c20746573742063617365000000000000000000000000000000000000905060001515610398576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252600e8152602001807f4661696c2074657374206361736500000000000000000000000000000000000081525060200191505060405180910390fd5b90565b606060405190507f414141414141414141414141414141414141414141414141414141414141414181527f41414141414141414141414141414141000000000000000000000000000000006020820152603081f300a165627a7a72305820063eaaf4a8908d67e7f82c71ba07e82f43c5688b71123ccaaa0a6abfa0279ff40029";

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

        //verify proxy ownership
        assertEq(proxy.owner(), this);
    }

    ///test 3 - build a proxy from DSProxyFactory (other owner) and verify logging
    function test_DSProxyFactoryBuildProcOtherOwner() public {
        address owner = address(0x123);
        address proxyAddr = factory.build(owner);
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

        //verify proxy ownership
        assertEq(proxy.owner(), owner);
    }

    ///test 4 - verify getting a cache
    function test_DSProxyCacheAddr1() public {
        DSProxy p = new DSProxy(cache);
        assertTrue(address(p) > 0x0);
        address cacheAddr = p.cache();
        assertTrue(cacheAddr == address(cache));
        assertTrue(cacheAddr != 0x0);
    }

    ///test 5 - verify setting a new cache
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

    ///test 6 - execute an action through proxy and verify caching
    function test_DSProxyExecute() public {
        //function identifier for getBytes32()
        bytes memory calldata = hex"1f903037";

        //verify contract is not stored in cache
        assertEq(cache.read(testCode), 0x0);

        //deploy and call the contracts code
        (address target, bytes memory response) = proxy.execute(testCode, calldata);

        bytes32 response32;

        assembly {
            response32 := mload(add(response, 32))
        }

        //verify we got correct response
        assertEq32(response32, bytes32("Hello"));

        //verify contract is stored in cache
        assertTrue(cache.read(testCode) != 0x0);

        //call the contracts code using target address
        response = proxy.execute(target, calldata);

        assembly {
            response32 := mload(add(response, 32))
        }

        //verify we got correct response
        assertEq32(response32, bytes32("Hello"));
    }

    ///test 7 - execute an action through proxy which returns more than 1 value
    function test_DSProxyExecute2Values() public {
        //function identifier for getBytes32AndUint()
        bytes memory calldata = hex"8583cc0b";

        //deploy and call the contracts code
        (, bytes memory response) = proxy.execute(testCode, calldata);

        bytes32 response32;
        uint responseUint;

        assembly {
            response32 := mload(add(response, 0x20))
            responseUint := mload(add(response, 0x40))
        }

        //verify we got correct response
        assertEq32(response32, bytes32("Bye"));
        assertEq(responseUint, uint(150));
    }

    ///test 8 - execute an action through proxy which returns multiple values in a bytes32[] format
    function test_DSProxyExecuteMultipleValues() public {
        //function identifier for getMultipleValues(uint256) uint = 10000
        bytes memory calldata = hex"5f7a3d160000000000000000000000000000000000000000000000000000000000002710";

        //deploy and call the contracts code
        (, bytes memory response) = proxy.execute(testCode, calldata);

        uint size;
        bytes32 response32;

        assembly {
            size := mload(add(response, 0x40))
        }

        assertEq(size, 10000);

        for (uint i = 0; i < size; i++) {
            assembly {
                response32 := mload(add(response, mul(32, add(i, 3))))
            }
            assertEq32(response32, bytes32(i));
        }
    }

    ///test 9 - execute an action through proxy which returns a value not multiple of 32
    function test_DSProxyExecuteNot32Multiple() public {
        //function identifier for get48Bytes()
        bytes memory calldata = hex"aa4025cc";

        //deploy and call the contracts code
        (, bytes memory response) = proxy.execute(testCode, calldata);

        bytes memory test = new bytes(48);
        test = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

        assertEq0(response, test);
    }

    ///test 10 - execute an action through proxy which reverts
    function test_DSProxyExecuteFailMethod() public {
        address target = proxy;
        bytes memory execute = hex"1cff79cd"; // execute(address,bytes)
        address testContract = new TestContract();
        bytes memory fail = hex"a9cc4718"; // fail()
        bytes memory calldata;

        assembly {
            calldata := mload(0x40)
            let size := 0x64
            mstore(0x40, add(calldata, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(calldata, size)
            mstore(add(calldata, 0x20), mload(add(execute, 0x20)))
            mstore(add(calldata, 0x24), testContract)
            mstore(add(calldata, 0x44), 0x20)
            mstore(add(calldata, 0x64), mload(add(fail, 0x20)))
        }

        // emit logs(calldata);

        bool succeeded;
        bytes memory response;

        assembly {
            succeeded := call(sub(gas, 5000), target, 0, add(calldata, 0x20), mload(calldata), 0, 0)
            let size := returndatasize

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)
        }
        assertTrue(!succeeded);
        // logs(response);
    }

    ///test 11 - deposit ETH to Proxy
    function test_DSProxyDepositETH() public {
        assertEq(address(proxy).balance, 0);
        assertTrue(address(proxy).call.value(10)());
        assertEq(address(proxy).balance, 10);
    }

    ///test 12 - withdraw ETH from Proxy
    function test_DSProxyWithdrawETH() public {
        assert(address(proxy).call.value(10)());
        assertEq(address(proxy).balance, 10);
        uint256 myBalance = address(this).balance;
        address withdrawFunds = new WithdrawFunds();
        bytes memory calldata = hex"2e1a7d4d0000000000000000000000000000000000000000000000000000000000000005"; // withdraw(5)
        proxy.execute(withdrawFunds, calldata);
        assertEq(address(proxy).balance, 5);
        assertEq(address(this).balance, myBalance + 5);
    }

    function() public payable {
    }
}
