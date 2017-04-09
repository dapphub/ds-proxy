ds-proxy

This repository contains a very useful utility called a "proxy".
It is deployed as a standalone contract, and can then be used by the owner to execute code.

A user would pass in the bytecode for the contract as well as the calldata for the code they want to execute.

The proxy will create a contract using the bytecode. Then it will delegatecall the function and arguments specified in the calldata.
Loading in this code is more efficient than jumping to it.

It has several important use cases.

1. Allow actions to be executed through the proxys identity
This can be very useful for securing complex applications. Because delegatecall retains msg.sender and msg.value properties, internal functions can be set to only accept calls coming from the proxy through an ownership model like ds-auth. In this manner as long as the proxy is not compromised, the internal system is protected from outsider access. Should the owner of the internal calls ever need to be changed, this is as simple as updating the owner of ds-proxy rather than manualy updating each individual internal function call. In short, making it much more secure and adaptable.

2. Executes a sequence of actions atomically
Due to restrictions in the EVM instruction set such as being unable to be nested dynamically sized types and arguments, 1 transaction could be done at a time. Since ds-proxy takes in bytecode of a contract, rather than relying on a predeployed contract, customized "script" contracts can be used. These script contracts share a very a important property in that they enable a sequence of actions to be executed atomically (all or nothing). This prevents having to manually rollback writes to contracts when a single transaction fails in a set of transactions.

How To Use:
(Note the examples assume the user is using DappHub's utilities dapp-cli and seth)

1a. Deploy DSProxyFactory. (Optional, DSProxy can be deployed directly)
    E.g. dapp create DSProxyFactory    

1b. Call the build function in DSProxyFactory to create a proxy for you. (Optional, see above)
    E.g. seth send <DSProxyFactoryAddr> "build()(address)"

2. Create a contract and compile using solc.
The resulting .bin contains the bytecode of the contract.

3. Get the calldata for the function and arguments you want to execute
   E.g. seth calldata "<functionName>(<argType1>,<argType2>...<argTypeN>)(<returnArgType>)" <arg1> <arg2> <argN>

4. Pass the contract bytecode and calldata to the execute function inside the deployed DSProxy.
   E.g. seth send <DSProxyAddr> "execute(bytes,bytes)(bytes32)" <ContractByteCode> <CallData>
   


