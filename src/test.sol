pragma solidity ^0.4.8;

import "ds-test/test.sol";

contract Test is DSTest {
    function test_basic_sanity() {
        assert(true);
    }

    function testFail_basic_sanity() {
        assert(false);
    }
}
