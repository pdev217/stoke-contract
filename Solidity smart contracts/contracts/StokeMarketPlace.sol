// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
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
        uint256 time;
        uint256 minPrice;
        bool inList;
        uint256 bidAmount;
    }

    struct fixedSale {
        uint256 time;
        uint256 price;
        bool inList;
    }

    uint256 public tokenIdMint;
    uint256 public fixedFee = 2;
    uint256 public auctionFee = 2;

    mapping(uint256 => fixedSale) nftPrice;
    mapping(uint256 => uint256[]) public collectionStored;
    mapping(uint256 => collectionInfo) collection;
    mapping(address => uint256[]) public userInfo;
    mapping(address => uint256) public totalCollection;
    mapping(uint256 => uint256) public totalNft;
    uint256[] saleNft;
    uint256[] auctionNft;
    mapping(uint256 => uint256) public saleNftList;
    mapping(uint256 => uint256) public auctionNftList;
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
        Token memory token
    ) public {
        require(
            offer.expiresAt >= block.timestamp,
            "MarketPlace: the offer expired"
        );

        //calc service fee -2.5%
        uint marketFeePercentage = 25;
        uint commissionDenominator = 1000;
        uint serviceFee = (offer.amount * marketFeePercentage) /
            commissionDenominator;

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
        console.log(success);

        //transfer nft
        (bool success1, ) = _nftContract.call(
            abi.encodeWithSignature(
                "createToken(uint256,address,string)",
                token.tokenId,
                offer.sender,
                token.tokenURI
            )
        );
        console.log(success1);

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
        uint256 _tokenId,
        uint256 _price,
        uint256 _time,
        address _nftContract
    ) public {
        require(!timeForAuction[_tokenId].inList, "already in sale");
        require(!nftPrice[_tokenId].inList, "already in sale");
        require(
            IERC721(_nftContract).ownerOf(_tokenId) == msg.sender,
            "You are not owner"
        );
        timeForFixed[_tokenId].time = block.timestamp + _time;
        timeForFixed[_tokenId].price = _price;
        timeForFixed[_tokenId].inList = true;
        originalOwner[_tokenId] == msg.sender;
        nftPrice[_tokenId].price = _price;
        nftPrice[_tokenId].inList = true;
        saleNftList[_tokenId] = saleNft.length;
        saleNft.push(_tokenId);
        address firstowner = IERC721(_nftContract).ownerOf(_tokenId);
        IERC721(_nftContract).transferFrom(firstowner, address(this), _tokenId);
    }

    function cancelFixedSale(uint256 _tokenId, address _nftContract) external {
        require(
            originalOwner[_tokenId] == msg.sender,
            "you are not original owner"
        );
        nftPrice[_tokenId].price = 0;
        nftPrice[_tokenId].inList = false;
        nftPrice[_tokenId].inList = false;
        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
        delete saleNft[(saleNftList[_tokenId])];
    }

    function buyNft(uint256 _tokenId, address _nftContract) external payable {
        require(timeForFixed[_tokenId].inList, "input duration time");
        require(nftPrice[_tokenId].inList, "nft not in sale");
        require(
            timeForFixed[_tokenId].time >= block.timestamp,
            "fixed sale end"
        );
        uint256 val = uint256(100) - fixedFee;

        uint256 values = msg.value;
        require(values >= nftPrice[_tokenId].price, "price should be greater");
        uint256 amount = ((values * uint256(val)) / uint256(100));
        uint256 ownerinterest = ((values * uint256(fixedFee)) / uint256(100));
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
        uint256 _tokenId,
        uint256 _price,
        uint256 _time,
        address _nftContract
    ) external {
        require(!nftStakeState[_tokenId], "nft is stake");
        require(!timeForAuction[_tokenId].inList, "already in sale");
        require(!nftPrice[_tokenId].inList, "already in sale");
        require(
            IERC721(_nftContract).ownerOf(_tokenId) == msg.sender,
            "You are not owner"
        );
        timeForAuction[_tokenId].time = block.timestamp + _time;
        timeForAuction[_tokenId].minPrice = _price;
        timeForAuction[_tokenId].inList = true;
        auctionNftList[_tokenId] = auctionNft.length;
        auctionNft.push(_tokenId);
        address firstowner = IERC721(_nftContract).ownerOf(_tokenId);
        IERC721(_nftContract).transferFrom(firstowner, address(this), _tokenId);
    }

    function buyAuction(uint256 _tokenId) external payable {
        require(timeForAuction[_tokenId].inList, "nft not in sale");
        require(
            msg.value >= timeForAuction[_tokenId].minPrice,
            "amount should be greater"
        );
        require(
            msg.value > timeForAuction[_tokenId].bidAmount,
            "previous bidding amount"
        );
        require(
            timeForAuction[_tokenId].time >= block.timestamp,
            "auction end"
        );
        timeForAuction[_tokenId].bidAmount = msg.value;
        amountForAuction[_tokenId][msg.sender] = msg.value;
        finalOwner[_tokenId] = msg.sender;
        uint256 values = msg.value;
        (bool success, ) = address(this).call{value: values}("");
        require(success, "refund failed");
    }

    function upgradeAuction(uint256 _tokenId, bool choice) external payable {
        require(
            timeForAuction[_tokenId].time >= block.timestamp,
            "auction end"
        );
        uint256 val = uint256(100) - auctionFee;
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
                uint256 amount = ((totalamount * uint256(val)) / uint256(100));
                uint256 ownerinterest = ((totalamount * uint256(auctionFee)) /
                    uint256(100));
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
        timeForAuction[_tokenId].time = 0;
        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
        delete auctionNft[(auctionNftList[_tokenId])];
    }

    function auctionDetail(uint256 _tokenId)
        external
        view
        returns (uint256, address)
    {
        return (timeForAuction[_tokenId].bidAmount, finalOwner[_tokenId]);
    }

    function timing(uint256 _tokenId) external view returns (uint256) {
        if (timeForAuction[_tokenId].time >= block.timestamp) {
            return (timeForAuction[_tokenId].time - block.timestamp);
        } else {
            return uint256(0);
        }
    }

    function setFixedFee(uint256 _fixedFee) external {
        fixedFee = _fixedFee;
    }

    function setAuctionFee(uint256 _auctionFee) external returns (uint256) {
        auctionFee = _auctionFee;
        return auctionFee;
    }

    function listSaleNft(uint256 _tokenId)
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
            saleNft,
            auctionNft,
            timeForAuction[_tokenId].minPrice,
            nftPrice[_tokenId].price
        );
    }
}
