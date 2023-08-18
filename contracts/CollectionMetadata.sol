// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CreatorControl.sol";

abstract contract CollectionMetadata is CreatorControl {
    string private _contractURI;

    event ContractURIUpdated(string newContractURI);

    constructor(string memory initialContractURI) {
        _contractURI = initialContractURI;
    }

    function setContractURI(string memory newContractURI) public onlyCreator {
        _contractURI = newContractURI;
        emit ContractURIUpdated(newContractURI);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}
