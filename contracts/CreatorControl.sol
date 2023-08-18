// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract CreatorControl {
    address payable internal _creator;

    event CreatorTransferred(address indexed previousCreator, address indexed newCreator);

    /**
     * @dev Initializes the contract setting the deployer as the initial creator.
     */
    constructor() {
        _creator = payable(msg.sender);
        emit CreatorTransferred(address(0), _creator);
    }

    /**
     * @dev Returns the address of the current creator.
     */
    function creator() public view returns (address) {
        return _creator;
    }

    /**
     * @dev Throws if called by any account other than the creator.
     */
    modifier onlyCreator() {
        require(_creator == msg.sender, "Caller is not the creator");
        _;
    }

    /**
     * @dev Transfers control of the contract to a new creator.
     * Can only be called by the current creator.
     * @param newCreator Address of the new creator.
     */
    function transferCreator(address payable newCreator) public onlyCreator {
        require(newCreator != address(0), "New creator is the zero address");
        emit CreatorTransferred(_creator, newCreator);
        _creator = newCreator;
    }
}
