// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SimpleStorage {
    uint public storedData;

    event Stored(address indexed _to, uint _amount);

    constructor(uint initVal) {
        emit Stored(msg.sender, initVal);
        storedData = initVal;
    }

    function set(uint x) public {
        emit Stored(msg.sender, x);
        storedData = x;
    }

    function get() view public returns (uint retVal) {
        return storedData;
    }
}
