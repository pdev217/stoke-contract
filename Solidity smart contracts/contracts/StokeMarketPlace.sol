// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// TODO: delete on production mode
import "hardhat/console.sol";

contract StokeMarketplace is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _offerCounter; // start from 1

    address payable public marketOwner;

    struct Offer {
        address sender;
        uint256 amount;
        uint256 expiresAt;
    }

    struct Token {
        uint256 tokenId;
        string tokenURI;
    }

    struct collectionInfo {
        address owner;
        bytes name;
        bytes displayName;
        bytes websiteURL;
        bytes description;
        bytes imgHash;
        uint256 marketFees;
    }

    struct auction {
        bool method;
        uint256 startTime;
        uint256 endTime;
        uint256 minPrice;
        uint256 maxPrice;
        bool inList;
        uint256 bidAmount;
    }

    struct fixedSale {
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        bool inList;
    }

    uint256 public tokenIdMint;
    uint8 public marketFee = 250;

    mapping(uint256 => fixedSale) nftPrice;
    mapping(uint256 => uint256[]) public collectionStored;
    mapping(uint256 => collectionInfo) collection;
    mapping(address => uint256[]) public userInfo;
    mapping(address => uint256) public totalCollection;
    mapping(uint256 => uint256) public totalNft;
    uint256[] fixedSaleNfts;
    uint256[] auctionSaleNft;
    mapping(uint256 => uint256) public fixedSaleNftList;
    mapping(uint256 => uint256) public auctionSaleNftList;
    mapping(uint256 => mapping(uint256 => uint256)) idNumber;
    mapping(uint256 => fixedSale) timeForFixed;
    mapping(uint256 => auction) timeForAuction;
    mapping(uint256 => mapping(address => uint256)) amountForAuction;
    mapping(uint256 => uint256) public nftCollectionId;
    mapping(uint256 => address) finalOwner;
    mapping(uint256 => bool) public nftStakeState;
    mapping(uint256 => address) public originalOwner;

    constructor() {
        marketOwner = payable(msg.sender);
    }

    modifier onlyByOwner() {
        require(
            msg.sender == marketOwner,
            "You are not an owner of Marketplace."
        );
        _;
    }

    function accept(
        Offer memory offer,
        address WETH,
        address _nftContract,
        Token memory token,
        bytes memory signature
    ) public {
        require(
            offer.expiresAt >= block.timestamp,
            "MarketPlace: the offer expired"
        );
        //calc service fee -2.5%
        uint256 serviceFee = (offer.amount * marketFee) / 10000;
        uint256 balance = IERC20(WETH).balanceOf(offer.sender);
        require(
            balance >= offer.amount,
            "MarketPlace: Offer sender has no enought token"
        );
        //approve feature
        (bool success, ) = WETH.call(
            abi.encodeWithSignature(
                "_approve(address,address,uint256)",
                offer.sender,
                address(this),
                offer.amount
            )
        );
        require(success, "_approve encodeWithSignature");
        //transfer nft
        // StokeNFT(_nftContract).safeTransferFromWithPermit(
        //     msg.sender,
        //     offer.sender,
        //     token.tokenId,
        //     "",
        //     offer.expiresAt,
        //     signature
        // );
        (bool success1, ) = _nftContract.call(
            abi.encodeWithSignature(
                "safeTransferFromWithPermit(address,address,uint256,bytes,uint256,bytes)",
                msg.sender,
                offer.sender,
                token.tokenId,
                "",
                offer.expiresAt,
                signature
            )
        );

        // require(success1, "createToken encodeWithSignature");
        require(
            IERC20(WETH).allowance(offer.sender, address(this)) == offer.amount,
            "insufficient amount"
        );

        //transfer weth token
        IERC20(WETH).transferFrom(
            offer.sender,
            msg.sender,
            (offer.amount - serviceFee)
        );
        //transfer market fee to market owner
        IERC20(WETH).transferFrom(offer.sender, marketOwner, serviceFee);
    }

    function buyOrder(
        address payable _recipient,
        uint256 _tokenId,
        address _nftContract
    ) public payable {
        require(
            IERC721(_nftContract).getApproved(_tokenId) == address(this),
            "MarketPlace: The token must be approved to marketplace"
        );
        //transfer NFT
        IERC721(_nftContract).transferFrom(_recipient, msg.sender, _tokenId);
        //transfer ETH
        _recipient.transfer(msg.value);
    }

    function fixedSales(
        uint256[] memory _tokenIds,
        uint256[] memory _prices,
        uint256[] memory _startTimes,
        uint256[] memory _endTimes,
        address[] memory _nftContracts
    ) public {
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(!timeForAuction[_tokenId].inList, "already in sale");
            require(!nftPrice[_tokenId].inList, "already in sale");
            require(
                IERC721(_nftContracts[i]).ownerOf(_tokenId) == msg.sender,
                "You are not owner"
            );
            timeForFixed[_tokenId].startTime = _startTimes[i];
            timeForFixed[_tokenId].endTime = _endTimes[i];
            timeForFixed[_tokenId].price = _prices[i];
            timeForFixed[_tokenId].inList = true;
            nftPrice[_tokenId].price = _prices[i];
            nftPrice[_tokenId].inList = true;
            fixedSaleNftList[_tokenId] = fixedSaleNfts.length;
            fixedSaleNfts.push(_tokenId);
            address firstowner = IERC721(_nftContracts[i]).ownerOf(_tokenId);
            originalOwner[_tokenId] = firstowner;
            IERC721(_nftContracts[i]).transferFrom(
                firstowner,
                address(this),
                _tokenId
            );
        }
    }

    function cancelFixedSale(uint256 _tokenId, address _nftContract) external {
        require(
            originalOwner[_tokenId] == msg.sender,
            "you are not original owner"
        );
        nftPrice[_tokenId].price = 0;
        nftPrice[_tokenId].inList = false;
        timeForFixed[_tokenId].inList = false;
        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
        delete fixedSaleNfts[(fixedSaleNftList[_tokenId])];
    }

    function buyNft(uint256 _tokenId, address _nftContract) external payable {
        require(timeForFixed[_tokenId].inList, "input duration time");
        require(nftPrice[_tokenId].inList, "nft not in sale");
        require(
            timeForFixed[_tokenId].startTime <= block.timestamp,
            "fixed sale not started"
        );
        require(
            timeForFixed[_tokenId].endTime >= block.timestamp,
            "fixed sale ended"
        );
        uint16 val = 10000 - marketFee;
        uint256 values = msg.value;
        require(values >= nftPrice[_tokenId].price, "price should be greater");
        uint256 amount = ((values * val) / 10000);
        uint256 ownerinterest = ((values * marketFee) / 10000);
        address firstowner = originalOwner[_tokenId];
        (bool success, ) = firstowner.call{value: amount}("");
        require(success, "refund failed");
        (bool stateOwnerinterset, ) = marketOwner.call{value: ownerinterest}(
            ""
        );
        require(stateOwnerinterset, "refund failed");
        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
    }

    // Start auction
    function startAuction(
        uint256[] memory _tokenIds,
        bool[] memory _methods,
        uint256[] memory _minPrices,
        uint256[] memory _maxPrices,
        uint256[] memory _startTimes,
        uint256[] memory _endTimes,
        address[] memory _nftContracts
    ) external {
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(!nftStakeState[_tokenId], "nft is stake");
            require(!timeForAuction[_tokenId].inList, "already in sale");
            require(!nftPrice[_tokenId].inList, "already in sale");
            require(
                IERC721(_nftContracts[i]).ownerOf(_tokenId) == msg.sender,
                "You are not owner"
            );
            timeForAuction[_tokenId].method = _methods[i];
            timeForAuction[_tokenId].startTime = _startTimes[i];
            timeForAuction[_tokenId].endTime = _endTimes[i];
            timeForAuction[_tokenId].inList = true;
            auctionSaleNftList[_tokenId] = auctionSaleNft.length;
            auctionSaleNft.push(_tokenId);
            // for method
            if (timeForAuction[_tokenId].method) {
                timeForAuction[_tokenId].minPrice = _minPrices[i];
            } else {
                timeForAuction[_tokenId].maxPrice = _maxPrices[i];
                timeForAuction[_tokenId].minPrice = _minPrices[i];
            }
            address firstowner = IERC721(_nftContracts[i]).ownerOf(_tokenId);
            IERC721(_nftContracts[i]).transferFrom(
                firstowner,
                address(this),
                _tokenId
            );
        }
    }

    function buyAuction(uint256 _tokenId) external payable {
        require(timeForAuction[_tokenId].inList, "nft not in sale");
        require(
            timeForAuction[_tokenId].startTime <= block.timestamp,
            "auction sale not started"
        );
        require(
            timeForAuction[_tokenId].endTime >= block.timestamp,
            "auction sale not ended"
        );
        require(
            msg.value >= timeForAuction[_tokenId].minPrice,
            "amount should be greater"
        );
        if (timeForAuction[_tokenId].method) {
            require(
                msg.value > timeForAuction[_tokenId].bidAmount,
                "previous bidding amount"
            );
        } else {
            require(
                msg.value <= timeForAuction[_tokenId].maxPrice,
                "amount should be less"
            );
            require(
                msg.value < timeForAuction[_tokenId].bidAmount,
                "previous bidding amount"
            );
        }
        timeForAuction[_tokenId].bidAmount = msg.value;
        amountForAuction[_tokenId][msg.sender] = msg.value;
        finalOwner[_tokenId] = msg.sender;
        uint256 values = msg.value;
        (bool success, ) = address(this).call{value: values}("");
        require(success, "refund failed");
    }

    function upgradeAuction(uint256 _tokenId, bool choice) external payable {
        require(
            timeForAuction[_tokenId].startTime <= block.timestamp &&
                timeForAuction[_tokenId].endTime >= block.timestamp,
            "auction sale not started or ended"
        );
        uint16 val = 10000 - marketFee;
        if (choice) {
            amountForAuction[_tokenId][msg.sender] += msg.value;
            if (
                amountForAuction[_tokenId][msg.sender] >
                timeForAuction[_tokenId].bidAmount
            ) {
                timeForAuction[_tokenId].bidAmount = msg.value;
                finalOwner[_tokenId] = msg.sender;
                uint256 values = msg.value;
                (bool success, ) = address(this).call{value: values}("");
                require(success, "refund failed");
            }
        } else {
            if (finalOwner[_tokenId] != msg.sender) {
                require(
                    amountForAuction[_tokenId][msg.sender] > 0,
                    "You dont allow"
                );
                uint256 totalamount = amountForAuction[_tokenId][msg.sender];
                uint256 amount = ((totalamount * val) / 10000);
                uint256 ownerinterest = ((totalamount * marketFee) /
                    10000);
                (bool success, ) = msg.sender.call{value: amount}("");
                require(success, "refund failed");
                (bool result, ) = marketOwner.call{value: ownerinterest}("");
                require(result, "refund failed");
                amountForAuction[_tokenId][msg.sender] = 0;
            }
        }
    }

    function removeFromAuction(uint256 _tokenId, address _nftContract)
        external
    {
        require(
            originalOwner[_tokenId] == msg.sender,
            "You are not originalOwner"
        );
        timeForAuction[_tokenId].minPrice = 0;
        timeForAuction[_tokenId].bidAmount = 0;
        timeForAuction[_tokenId].inList = false;
        timeForAuction[_tokenId].startTime = 0;
        timeForAuction[_tokenId].endTime = 0;
        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
        delete auctionSaleNft[(auctionSaleNftList[_tokenId])];
    }

    function auctionDetail(uint256 _tokenId)
        external
        view
        returns (uint256, address)
    {
        return (timeForAuction[_tokenId].bidAmount, finalOwner[_tokenId]);
    }

    function timing(uint256 _tokenId) external view returns (uint256) {
        if (timeForAuction[_tokenId].endTime >= block.timestamp) {
            return (timeForAuction[_tokenId].endTime - block.timestamp);
        } else {
            return 0;
        }
    }

    function setMarketFee(uint8 _marketFee) external {
        marketFee = _marketFee;
    }

    function listfixedSaleNfts(uint256 _tokenId)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256,
            uint256
        )
    {
        return (
            fixedSaleNfts,
            auctionSaleNft,
            timeForAuction[_tokenId].minPrice,
            nftPrice[_tokenId].price
        );
    }
}
