// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract StokeNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenCounter;
    constructor() ERC721("StokeNFT", "NFT") {}

    struct Token {
        uint256 tokenId;
    }
    
    mapping(uint256 => Token) public tokens;

     function totalSupply() public view returns (uint256) {
        return _tokenCounter.current();
    }

    function createToken(uint256 _tokenId, address recipient, string memory tokenURI) public returns (uint256) {
        _tokenCounter.increment();

        uint256 id = _tokenCounter.current();

        bool IsExist = _exists(_tokenId);

        if(IsExist) {
            address nftOwner = ownerOf(_tokenId);
            _transfer(nftOwner, recipient, _tokenId);
        }else {
            _safeMint(recipient, _tokenId);
            _setTokenURI(_tokenId, tokenURI);

            tokens[id] = Token(
                _tokenId
            );
        }

        return _tokenId;
    }

    function createOrder(string memory _tokenURI, uint256 _tokenId, address marketContract) public {
        _tokenCounter.increment();
        uint256 id = _tokenCounter.current();

        _safeMint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);

        tokens[id] = Token(
            _tokenId
        );

        _approve(marketContract, _tokenId);
    }

    function IsExistToken(uint256 _tokenId) public view returns(bool){
        bool state = _exists(_tokenId);

        return state;
    }
}