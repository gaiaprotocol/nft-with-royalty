// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./CreatorControl.sol";

abstract contract TokenMetadata is ERC721, CreatorControl {
    event SetBaseURI(string baseURI);
    event MetadataUpdate(uint256 _tokenId);

    string internal __baseURI;
    mapping(uint256 => string) internal _tokenURIs;

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        __baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string memory baseURI) public onlyCreator {
        __baseURI = baseURI;
        emit SetBaseURI(baseURI);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;

        emit MetadataUpdate(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyCreator {
        _requireMinted(tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_tokenURI).length > 0) return _tokenURI;
        return super.tokenURI(tokenId);
    }
}
