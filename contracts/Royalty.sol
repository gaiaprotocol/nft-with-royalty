// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Contributor.sol";

abstract contract Royalty is Contributor {
    uint256 internal _royaltyPercentage; // Creator's royalty percentage (e.g., 1000 means 10%)
    uint256 internal _contributorPercentage; // Contributor's royalty percentage

    event RoyaltyPercentageChanged(uint256 newPercentage);
    event ContributorPercentageChanged(uint256 newContributorPercentage);

    constructor(uint256 initialCreatorPercentage, uint256 initialContributorPercentage) {
        require(initialCreatorPercentage + initialContributorPercentage <= 10000, "Total percentage exceeds 100%");

        _royaltyPercentage = initialCreatorPercentage;
        _contributorPercentage = initialContributorPercentage;
    }

    function getRoyaltyPercentage() public view returns (uint256) {
        return _royaltyPercentage;
    }

    function setRoyaltyPercentage(uint256 newPercentage) public onlyCreator {
        require(newPercentage + _contributorPercentage <= 10000, "Total percentage exceeds 100%");

        _royaltyPercentage = newPercentage;
        emit RoyaltyPercentageChanged(newPercentage);
    }

    function setContributorPercentage(uint256 newPercentage) public onlyCreator {
        require(newPercentage + _royaltyPercentage <= 10000, "Total percentage exceeds 100%");

        _contributorPercentage = newPercentage;
        emit ContributorPercentageChanged(newPercentage);
    }

    function getContributorPercentage() public view returns (uint256) {
        return _contributorPercentage;
    }
}
