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

pragma solidity >=0.5.0 <0.6.0;

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
    function getMultipleValues(uint amount) public pure returns (bytes32[] memory result) {
        result = new bytes32[](amount);
        for (uint i = 0; i < amount; i++) {
            result[i] = bytes32(i);
        }
    }
    function get48Bytes() public pure returns (bytes memory result) {
        assembly {
            result := mload(0x40)
            mstore(result, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
            mstore(add(result, 0x20), "AAAAAAAAAAAAAAAA")
            return(result, 0x30)
        }
    }

    function fail() public pure {
        require(false, "Fail test case");
    }
}

contract TestFullAssemblyContract {
    function() external {
        assembly {
            let message := mload(0x40)
            mstore(message, "Fail test case")
            revert(message, 0xe)
        }
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

    bytes testCode = hex"608060405234801561001057600080fd5b506103da806100206000396000f30060806040526004361061006d576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680631f903037146100725780635f7a3d16146100a55780638583cc0b14610127578063a9cc471814610161578063aa4025cc14610178575b600080fd5b34801561007e57600080fd5b50610087610208565b60405180826000191660001916815260200191505060405180910390f35b3480156100b157600080fd5b506100d060048036038101908080359060200190929190505050610230565b6040518080602001828103825283818151815260200191508051906020019060200280838360005b838110156101135780820151818401526020810190506100f8565b505050509050019250505060405180910390f35b34801561013357600080fd5b5061013c6102b0565b6040518083600019166000191681526020018281526020019250505060405180910390f35b34801561016d57600080fd5b506101766102e1565b005b34801561018457600080fd5b5061018d610359565b6040518080602001828103825283818151815260200191508051906020019080838360005b838110156101cd5780820151818401526020810190506101b2565b50505050905090810190601f1680156101fa5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b60007f48656c6c6f000000000000000000000000000000000000000000000000000000905090565b60606000826040519080825280602002602001820160405280156102635781602001602082028038833980820191505090505b509150600090505b828110156102aa5780600102828281518110151561028557fe5b906020019060200201906000191690816000191681525050808060010191505061026b565b50919050565b6000807f42796500000000000000000000000000000000000000000000000000000000006096809050915091509091565b60001515610357576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252600e8152602001807f4661696c2074657374206361736500000000000000000000000000000000000081525060200191505060405180910390fd5b565b606060405190507f414141414141414141414141414141414141414141414141414141414141414181527f41414141414141414141414141414141000000000000000000000000000000006020820152603081f300a165627a7a72305820e929b77ffa3b36f7f7ea1d39bee3c7fa4a921b5bf4d14e9db75e23b8d209fb8c0029";

    function setUp() public {
        factory = new DSProxyFactory();
        cache = new DSProxyCache();
        proxy = new DSProxy(address(cache));
    }

    ///test1 - check that DSProxyFactory creates a cache
    function test_DSProxyFactoryCheckCache() public {
        assertTrue(address(factory.cache) != address(0));
    }

    ///test 2 - build a proxy from DSProxyFactory and verify logging
    function test_DSProxyFactoryBuildProc() public {
        address payable proxyAddr = factory.build();
        assertTrue(proxyAddr != address(0));
        proxy = DSProxy(proxyAddr);

        uint codeSize;
        assembly {
            codeSize := extcodesize(proxyAddr)
        }
        //verify proxy was deployed successfully
        assertTrue(codeSize != 0);

        //verify proxy creation was logged
        assertTrue(factory.isProxy(proxyAddr));

        //verify logging doesnt return false positives
        address notProxy = 0xd2A49A27F3E68d9ab1973849eaA0BEC41A6592Ed;
        assertTrue(!factory.isProxy(notProxy));

        //verify proxy ownership
        assertEq(proxy.owner(), address(this));
    }

    ///test 3 - build a proxy from DSProxyFactory (other owner) and verify logging
    function test_DSProxyFactoryBuildProcOtherOwner() public {
        address owner = address(0x123);
        address payable proxyAddr = factory.build(owner);
        assertTrue(proxyAddr != address(0));
        proxy = DSProxy(proxyAddr);

        uint codeSize;
        assembly {
            codeSize := extcodesize(proxyAddr)
        }
        //verify proxy was deployed successfully
        assertTrue(codeSize != 0);

        //verify proxy creation was logged
        assertTrue(factory.isProxy(proxyAddr));

        //verify proxy ownership
        assertEq(proxy.owner(), owner);
    }

    ///test 4 - verify getting a cache
    function test_DSProxyCacheAddr1() public {
        DSProxy p = new DSProxy(address(cache));
        assertTrue(address(p) != address(0));
        address cacheAddr = address(p.cache());
        assertTrue(cacheAddr == address(cache));
        assertTrue(cacheAddr != address(0));
    }

    ///test 5 - verify setting a new cache
    function test_DSProxyCacheAddr2() public {
        DSProxy p = new DSProxy(address(cache));
        assertTrue(address(p) != address(0));
        address newCacheAddr = address(new DSProxyCache());
        address oldCacheAddr = address(cache);
        assertEq(address(p.cache()), oldCacheAddr);
        assertTrue(p.setCache(newCacheAddr));
        assertEq(address(p.cache()), newCacheAddr);
        assertTrue(oldCacheAddr != newCacheAddr);
    }

    ///test 6 - execute an action through proxy and verify caching
    function test_DSProxyExecute() public {
        bytes memory data = abi.encodeWithSignature("getBytes32()");

        //verify contract is not stored in cache
        assertEq(cache.read(testCode), address(0));

        //deploy and call the contracts code
        (address target, bytes memory response) = proxy.execute(testCode, data);

        bytes32 response32;

        assembly {
            response32 := mload(add(response, 32))
        }

        //verify we got correct response
        assertEq32(response32, bytes32("Hello"));

        //verify contract is stored in cache
        assertTrue(cache.read(testCode) != address(0));

        //call the contracts code using target address
        response = proxy.execute(target, data);

        assembly {
            response32 := mload(add(response, 32))
        }

        //verify we got correct response
        assertEq32(response32, bytes32("Hello"));
    }

    ///test 7 - execute an action through proxy which returns more than 1 value
    function test_DSProxyExecute2Values() public {
        bytes memory data = abi.encodeWithSignature("getBytes32AndUint()");

        //deploy and call the contracts code
        (, bytes memory response) = proxy.execute(testCode, data);

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
        bytes memory data = abi.encodeWithSignature("getMultipleValues(uint256)", 10000);

        //deploy and call the contracts code
        (, bytes memory response) = proxy.execute(testCode, data);

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
        bytes memory data = abi.encodeWithSignature("get48Bytes()");

        //deploy and call the contracts code
        (, bytes memory response) = proxy.execute(testCode, data);

        bytes memory test = new bytes(48);
        test = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

        assertEq0(response, test);
    }

    ///test 10 - execute an action through proxy which reverts via solidity require
    function test_DSProxyExecuteFailMethod() public {
        address payable target = address(proxy);
        address testContract = address(new TestContract());
        bytes memory data = abi.encodeWithSignature("execute(address,bytes)", bytes32(uint(address(testContract))), abi.encodeWithSignature("fail()"));

        bool succeeded;
        bytes memory sig;
        bytes memory message;

        assembly {
            succeeded := call(sub(gas, 5000), target, 0, add(data, 0x20), mload(data), 0, 0)

            let size := returndatasize

            let response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            size := 0x4
            sig := mload(0x40)
            mstore(sig, size)
            mstore(0x40, add(sig, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            returndatacopy(add(sig, 0x20), 0, size)

            size := mload(add(response, 0x44))
            message := mload(0x40)
            mstore(message, size)
            mstore(0x40, add(message, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            returndatacopy(add(message, 0x20), 0x44, size)
        }
        assertTrue(!succeeded);
        assertEq0(sig, abi.encodeWithSignature("Error(string)"));
        assertEq0(message, "Fail test case");
    }

    ///test 11 - execute an action through proxy which reverts via a pure assembly function
    function test_DSProxyExecuteFailMethodAssembly() public {
        address payable target = address(proxy);
        address testContract = address(new TestFullAssemblyContract());
        bytes memory data = abi.encodeWithSignature("execute(address,bytes)", bytes32(uint(address(testContract))), hex"");

        bool succeeded;
        bytes memory response;

        assembly {
            succeeded := call(sub(gas, 5000), target, 0, add(data, 0x20), mload(data), 0, 0)

            let size := returndatasize

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)
        }
        assertTrue(!succeeded);
        assertEq0(response, "Fail test case");
    }

    ///test 12 - deposit ETH to Proxy
    function test_DSProxyDepositETH() public {
        assertEq(address(proxy).balance, 0);
        (bool success,) = address(proxy).call.value(10)("");
        assertTrue(success);
        assertEq(address(proxy).balance, 10);
    }

    ///test 13 - withdraw ETH from Proxy
    function test_DSProxyWithdrawETH() public {
        (bool success,) = address(proxy).call.value(10)("");
        assertTrue(success);
        assertEq(address(proxy).balance, 10);
        uint256 myBalance = address(this).balance;
        address withdrawFunds = address(new WithdrawFunds());
        bytes memory data = abi.encodeWithSignature("withdraw(uint256)", 5);
        proxy.execute(withdrawFunds, data);
        assertEq(address(proxy).balance, 5);
        assertEq(address(this).balance, myBalance + 5);
    }

    function() external payable {
    }
}
