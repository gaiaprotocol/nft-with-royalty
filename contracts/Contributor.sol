// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CreatorControl.sol";

abstract contract Contributor is CreatorControl {
    address payable internal _contributor;

    event ContributorChanged(address newContributor);

    constructor(address payable initialContributor) {
        _contributor = initialContributor;
    }

    function setContributor(address payable contributorAddress) public onlyCreator {
        _contributor = contributorAddress;
        emit ContributorChanged(contributorAddress);
    }

    function getContributor() public view returns (address) {
        return _contributor;
    }
}
