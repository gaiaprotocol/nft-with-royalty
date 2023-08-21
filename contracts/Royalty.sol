// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Contributor.sol";

abstract contract Royalty is Contributor {
    uint256 internal _royaltyPercentage; // Creator's royalty percentage (e.g., 1000 means 10%)
    uint256 internal _contributorPercentage; // Contributor's royalty percentage
    
    uint256 private constant MAX_PERCENTAGE = 10000; // Represents 100% in the scaled percentage system

    event RoyaltyPercentageChanged(uint256 newPercentage);
    event ContributorPercentageChanged(uint256 newContributorPercentage);

    constructor(uint256 initialCreatorPercentage, uint256 initialContributorPercentage) {
        require(initialCreatorPercentage + initialContributorPercentage <= MAX_PERCENTAGE, "Total percentage exceeds 100%");

        _royaltyPercentage = initialCreatorPercentage;
        _contributorPercentage = initialContributorPercentage;
    }

    function getRoyaltyPercentage() public view returns (uint256) {
        return _royaltyPercentage;
    }

    function setRoyaltyPercentage(uint256 newPercentage) public onlyCreator {
        require(newPercentage + _contributorPercentage <= MAX_PERCENTAGE, "Total percentage exceeds 100%");

        _royaltyPercentage = newPercentage;
        emit RoyaltyPercentageChanged(newPercentage);
    }

    function setContributorPercentage(uint256 newPercentage) public onlyCreator {
        require(newPercentage + _royaltyPercentage <= MAX_PERCENTAGE, "Total percentage exceeds 100%");

        _contributorPercentage = newPercentage;
        emit ContributorPercentageChanged(newPercentage);
    }

    function getContributorPercentage() public view returns (uint256) {
        return _contributorPercentage;
    }
}
