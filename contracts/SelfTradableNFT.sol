// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./CollectionMetadata.sol";
import "./CreatorMintable.sol";
import "./Royalty.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SelfTradableNFT is CollectionMetadata, CreatorMintable, Royalty, ReentrancyGuard {
    using Address for address;
    using ECDSA for bytes32;

    bool private _isSelfTradableNFT = true;
    mapping(uint256 => bool) private _usedNonces;

    struct Trade {
        uint256 tokenId;
        uint256 price;
        address seller;
        address buyer;
        uint256 expiry;
        uint256 nonce;
    }

    event SetSelfTradableNFT(bool isSelfTradableNFT);
    event TradeCompleted(
        address indexed seller,
        address indexed buyer,
        uint256 tokenId,
        uint256 price,
        uint256 royaltyToCreator,
        uint256 royaltyToContributor
    );
    event BlacklistedTrade(bytes32 indexed tradeHash);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory initialContractURI,
        string memory initialTokenBaseURI,
        uint256 initialCreatorPercentage,
        uint256 initialContributorPercentage,
        address payable initialContributor
    )
        CollectionMetadata(initialContractURI)
        TokenMetadata(name_, symbol_, initialTokenBaseURI)
        Royalty(initialCreatorPercentage, initialContributorPercentage)
        Contributor(initialContributor)
    {}

    function setSelfTradableNFT(bool isSelfTradableNFT) public onlyCreator {
        _isSelfTradableNFT = isSelfTradableNFT;
        emit SetSelfTradableNFT(isSelfTradableNFT);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        if (!from.isContract() && _isSelfTradableNFT) {
            require(!msg.sender.isContract(), "SelfTradableNFT: token sender cannot be a contract");
            require(!to.isContract(), "SelfTradableNFT: token recipient cannot be a contract");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function executeTrade(
        Trade memory trade,
        bytes memory sellerSignature,
        bytes memory buyerSignature
    ) public payable nonReentrant {
        require(!_isSelfTradableNFT, "SelfTradableNFT: trade is disabled");
        require(!_usedNonces[trade.nonce], "SelfTradableNFT: This nonce has already been used or trade is blacklisted");
        require(block.timestamp <= trade.expiry, "SelfTradableNFT: Trade signature has expired");
        require(msg.value == trade.price, "SelfTradableNFT: Incorrect Ether sent");

        bytes32 tradeHash = keccak256(abi.encode(trade)).toEthSignedMessageHash();

        require(trade.seller == tradeHash.recover(sellerSignature), "SelfTradableNFT: Invalid seller signature");
        require(trade.buyer == tradeHash.recover(buyerSignature), "SelfTradableNFT: Invalid buyer signature");
        require(ownerOf(trade.tokenId) == trade.seller, "SelfTradableNFT: Seller does not own the token");

        uint256 royaltyAmountForCreator = (trade.price * _royaltyPercentage) / 10000;
        uint256 royaltyAmountForContributor = _contributor == address(0)
            ? 0
            : (trade.price * _contributorPercentage) / 10000;
        uint256 totalRoyalty = royaltyAmountForCreator + royaltyAmountForContributor;
        uint256 sellerReceivable = trade.price - totalRoyalty;

        _safeTransfer(trade.seller, trade.buyer, trade.tokenId, "");
        _usedNonces[trade.nonce] = true;

        emit TradeCompleted(
            trade.seller,
            trade.buyer,
            trade.tokenId,
            trade.price,
            royaltyAmountForCreator,
            royaltyAmountForContributor
        );

        _creator.transfer(royaltyAmountForCreator);
        if (_contributor != address(0)) {
            _contributor.transfer(royaltyAmountForContributor);
        }
        payable(trade.seller).transfer(sellerReceivable);
    }

    function blacklistTrade(Trade memory trade, bytes memory signerSignature) public {
        bytes32 tradeHash = keccak256(abi.encode(trade)).toEthSignedMessageHash();

        address signer = tradeHash.recover(signerSignature);
        require(
            signer == trade.seller || signer == trade.buyer,
            "SelfTradableNFT: Only seller or buyer can blacklist this trade"
        );

        _usedNonces[trade.nonce] = true;
        emit BlacklistedTrade(tradeHash);
    }
}
