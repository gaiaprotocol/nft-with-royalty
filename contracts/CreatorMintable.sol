// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./TokenMetadata.sol";

abstract contract CreatorMintable is TokenMetadata {
    function mint(address to, uint256 tokenId) public onlyCreator {
        _safeMint(to, tokenId);
    }

    function mint(address to, uint256 tokenId, string memory tokenURI) public onlyCreator {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }
}
