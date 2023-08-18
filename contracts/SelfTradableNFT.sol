// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./CollectionMetadata.sol";
import "./CreatorMintable.sol";
import "./Royalty.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SelfTradableNFT is CollectionMetadata, CreatorMintable, Royalty {
    using Address for address;
    using ECDSA for bytes32;

    bool private _isSelfTradableNFT = true;

    struct Trade {
        uint256 tokenId;
        uint256 price;
        address seller;
        address buyer;
        uint256 expiry; // Timestamp when the signature expires
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
        if (_isSelfTradableNFT) {
            require(!msg.sender.isContract(), "SelfTradableNFT: token sender cannot be a contract");
            require(!to.isContract(), "SelfTradableNFT: token recipient cannot be a contract");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function executeTrade(
        Trade memory trade,
        bytes memory sellerSignature,
        bytes memory buyerSignature
    ) public payable {
        require(block.timestamp <= trade.expiry, "Trade signature has expired");
        require(msg.value == trade.price, "Incorrect Ether sent");

        bytes32 tradeHash = keccak256(abi.encode(trade)).toEthSignedMessageHash();

        require(trade.seller == tradeHash.recover(sellerSignature), "Invalid seller signature");
        require(trade.buyer == tradeHash.recover(buyerSignature), "Invalid buyer signature");
        require(ownerOf(trade.tokenId) == trade.seller, "Seller does not own the token");

        // Calculate royalties
        uint256 royaltyAmountForCreator = (trade.price * _royaltyPercentage) / 10000;
        uint256 royaltyAmountForContributor = _contributor == address(0)
            ? 0
            : (trade.price * _contributorPercentage) / 10000;
        uint256 totalRoyalty = royaltyAmountForCreator + royaltyAmountForContributor;
        uint256 sellerReceivable = trade.price - totalRoyalty;

        // Transfer Ether to creator, contributor, and seller
        _creator.transfer(royaltyAmountForCreator);
        if (_contributor != address(0)) {
            _contributor.transfer(royaltyAmountForContributor);
        }
        payable(trade.seller).transfer(sellerReceivable);

        // Transfer the token
        _safeTransfer(trade.seller, trade.buyer, trade.tokenId, "");

        emit TradeCompleted(
            trade.seller,
            trade.buyer,
            trade.tokenId,
            trade.price,
            royaltyAmountForCreator,
            royaltyAmountForContributor
        );
    }
}
