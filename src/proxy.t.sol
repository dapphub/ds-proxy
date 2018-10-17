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

    bytes testCode = hex"608060405234801561001057600080fd5b506101f5806100206000396000f3006080604052600436106100565763ffffffff7c01000000000000000000000000000000000000000000000000000000006000350416631f903037811461005b5780635f7a3d16146100825780638583cc0b146100ea575b600080fd5b34801561006757600080fd5b50610070610118565b60408051918252519081900360200190f35b34801561008e57600080fd5b5061009a60043561013c565b60408051602080825283518183015283519192839290830191858101910280838360005b838110156100d65781810151838201526020016100be565b505050509050019250505060405180910390f35b3480156100f657600080fd5b506100ff6101a2565b6040805192835260208301919091528051918290030190f35b7f48656c6c6f00000000000000000000000000000000000000000000000000000090565b606060008260405190808252806020026020018201604052801561016a578160200160208202803883390190505b509150600090505b8281101561019c578151819083908290811061018a57fe5b60209081029091010152600101610172565b50919050565b7f4279650000000000000000000000000000000000000000000000000000000000609690915600a165627a7a72305820d88d7751122ce2c5d961517e1ebf9139561ee48207c58b09b323735ff005a7f20029";

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
            response32 := mload(add(response, 32))
            responseUint := mload(add(response, 64))
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
            size := mload(add(response, 64))
        }

        assertEq(size, 10000);

        for (uint i = 0; i < size; i++) {
            assembly {
                response32 := mload(add(response, mul(32, add(i, 3))))
            }
            assertEq32(response32, bytes32(i));
        }
    }

    ///test 9 - deposit ETH to Proxy
    function test_DSProxyDepositETH() public {
        assertEq(address(proxy).balance, 0);
        assertTrue(address(proxy).call.value(10)());
        assertEq(address(proxy).balance, 10);
    }

    ///test 10 - withdraw ETH from Proxy
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
