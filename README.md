<h2>DSProxy
  <small class="text-muted">
    <a href="https://github.com/dapphub/ds-proxy"><span class="fa fa-github"></span></a>
  </small>
</h2>

_Execute transactions & sequences of transactions by proxy_

This contract implements a very useful utility called a _proxy_. It is deployed 
as a standalone contract, and can then be used by the owner to execute code.

A user would pass in the bytecode for the contract as well as the calldata for 
the function they want to execute.

The proxy will create a contract using the bytecode. It will then delegatecall 
the function and arguments specified in the calldata. Loading in this code is 
more efficient than jumping to it.

### Use Cases

#### 1. Allow actions to be executed through the proxy identity

This can be very useful for securing complex applications. Because `delegatecall` 
retains `msg.sender` and `msg.value` properties, internal functions can be set 
to only accept calls coming from the proxy through an ownership model like 
[ds-auth](https://dapp.tools/dappsys/ds-auth.html). In this manner as long as 
the proxy is not compromised, the internal system is protected from outsider 
access. Should the owner of the internal calls ever need to be changed, this is 
as simple as updating the owner of `ds-proxy` rather than manually updating each 
individual internal function call, making it much more secure and adaptable.

#### 2. Execute a sequence of actions atomically

Due to restrictions in the EVM instruction set such as being unable to be nested 
dynamically sized types and arguments, 1 transaction could be done at a time. 
Since `ds-proxy` takes in bytecode of a contract, rather than relying on a 
pre-deployed contract, customized _script_ contracts can be used. These script 
contracts share a very a important property in that they enable a sequence of 
actions to be executed atomically (all or nothing). This prevents having to 
manually rollback writes to contracts when a single transaction fails in a set 
of transactions.

### Example Usage

Note: the examples assume the user is using Dapphub's [dapp](https://dapp.tools/dapp/) 
and [seth](https://dapp.tools/seth/) 

1. Deploy DSProxyFactory. (Optional - DSProxy can be deployed directly)    

   `dapp create DSProxyFactory`     

2. Call the build function in DSProxyFactory to create a proxy for you. (Optional)    

   `seth send <DSProxyFactoryAddr> "build()(address)"`    

3. Create a contract and compile using solc.    

   `dapp build MyCustomContract`    

3. Get the calldata for the function and arguments you want to execute     

   `seth calldata "<functionName>(<argType1>,<argType2>...<argTypeN>)(<returnArgType>)" <arg1> <arg2> <argN>`

4. Pass the contract bytecode and calldata to the execute function inside the deployed DSProxy.    
   `seth send <DSProxyAddr> "execute(bytes,bytes)(bytes32)" <ContractByteCode> <CallData>`
