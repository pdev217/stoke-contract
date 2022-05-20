// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@soliditylabs/erc721-permit/contracts/ERC721Permit.sol";

import "hardhat/console.sol";

contract StokeNFT is ERC721Permit("StokeNFT", "NFT") {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenCounter;

    struct Token {
        uint256 tokenId;
    }

    mapping(uint256 => Token) public tokens;

    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

    //     string memory _tokenURI = _tokenURIs[tokenId];
    //     string memory base = _baseURI();

    //     // If there is no base URI, return the token URI.
    //     if (bytes(base).length == 0) {
    //         return _tokenURI;
    //     }
    //     // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    //     if (bytes(_tokenURI).length > 0) {
    //         return string(abi.encodePacked(base, _tokenURI));
    //     }

    //     return super.tokenURI(tokenId);
    // }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function totalSupply() public view returns (uint256) {
        return _tokenCounter.current();
    }

    function createToken(
        uint256 _tokenId,
        address recipient,
        string memory tokenURI
    ) public returns (uint256) {
        _tokenCounter.increment();

        uint256 id = _tokenCounter.current();

        bool IsExist = _exists(_tokenId);

        if (IsExist) {
            address nftOwner = ownerOf(_tokenId);
            _transfer(nftOwner, recipient, _tokenId);
        } else {
            _safeMint(recipient, _tokenId);
            _setTokenURI(_tokenId, tokenURI);

            tokens[id] = Token(_tokenId);
        }

        return _tokenId;
    }

    function createOrder(
        string memory _tokenURI,
        uint256 _tokenId,
        address marketContract
    ) public {
        _tokenCounter.increment();
        uint256 id = _tokenCounter.current();

        _safeMint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);

        tokens[id] = Token(_tokenId);

        _approve(marketContract, _tokenId);
    }

    function IsExistToken(uint256 _tokenId) public view returns (bool) {
        bool state = _exists(_tokenId);

        return state;
    }
    // (address signer, ) = ECDSA.tryRecover(hash, signature);
    // bool isValidEOASignature = signer != address(0) &&
    //     _isApprovedOrOwner(signer, tokenId);

    // require(
    //     isValidEOASignature ||
    //     _isValidContractERC1271Signature(
    //         ownerOf(tokenId),
    //         hash, signature
    //     ) || _isValidContractERC1271Signature(
    //         getApproved(tokenId),
    //         hash,
    //         signature
    //     ),
    //     "ERC721Permit: invalid signature"
    // );

    // function _isValidContractERC1271Signature(
    //     address signer,
    //     bytes32 hash,
    //     bytes memory signature
    // ) private view returns (bool) {
    //     (bool success, bytes memory result) = signer.staticcall(
    //         abi.encodeWithSelector(
    //         IERC1271.isValidSignature.selector,
    //         hash,
    //         signature
    //         )
    //     );
    //     return (success &&
    //         result.length == 32 &&
    //         abi.decode(result,(bytes4))
    //             == IERC1271.isValidSignature.selector
    //     );
    // }
    
    /// @notice Allows to get approved using a permit and transfer in the same call
    /// @dev this supposes that the permit is for msg.sender
    /// @param from current owner
    /// @param to recipient
    /// @param tokenId the token id
    /// @param _data optional data to add
    /// @param deadline the deadline for the permit to be used
    /// @param signature of permit
    function safeTransferFromWithPermit(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data,
        uint256 deadline,
        bytes memory signature
    ) external {
        // use the permit to get msg.sender approved
        _permit(msg.sender, tokenId, deadline, signature);

        // do the transfer
        safeTransferFrom(from, to, tokenId, _data);
    }

}
