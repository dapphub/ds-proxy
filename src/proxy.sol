// Copyright 2016  Nexus Development, LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy of the License may be obtained at the following URL:
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

pragma solidity ^0.4.6;

import "./ds-auth/auth.sol";

contract DSProxyInterface {
    function forward(address target, uint eth_value, bytes calldata);
}

contract DSProxy8 is DSProxyInterface
                   , DSAuth
{
    function forward(address target, uint eth_value, bytes calldata)
        auth
    {
        if( !target.call.value(eth_value)(calldata) ) {
            throw;
        }
    }
    // legacy uPort compatability
    function forward_transaction(address t, uint v, bytes c) {
        forward(t, v, c);
    }
    // zeppelin compatability
    function forwardCall(address t, uint v, bytes c) {
        forward(t, v, c);
    }
}

contract DSProxy8Factory {
    mapping(address=>bool) public isProxy;
    function build() returns (DSProxy8) {
        var proxy = new DSProxy8();
        proxy.setOwner(msg.sender);
        isProxy[proxy] = true;
        return proxy;
    }
}
