// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable {

    string _baseTokenURI;
    uint256 public _price = 0.01 ether; //price of 1 CryptoDev NFT
    bool public _paused; //used to pause the contract in case of any emergency
    uint256 public maxTokenIds = 20;
    uint256 public tokenIds; //no. of token ids minted
    IWhitelist whitelist; // Whitelist contract instance
    bool public presaleStarted;
    uint256 public presaleEnded;

    modifier onlyWhenNotPaused() {
        require(!_paused, "Contract currently paused");
        _;
    }

    constructor (string memory baseURI, address whitelistContract) ERC721("Crypto Devs", "CD") {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

    // enable smart contract to accept tokens
    receive() external payable {}

    fallback() external payable {}

    //starts a presale for the whitelisted Address
    function startPresale() public onlyOwner {
        presaleStarted = true;
        presaleEnded = block.timestamp + 5 minutes;
    }

    function presaleMint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp < presaleEnded, "Presale has already ended");
        require(whitelist.whitelistedAddressess(msg.sender), "You are not whitelisted");
        require(tokenIds < maxTokenIds, "Exceeded maximum CryptoDevs Supply");
        require(msg.value >= _price, "Ether sent is not correct");

        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
    }

    function mint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp >= presaleEnded, "Presale has not ended yet");
        require(tokenIds < maxTokenIds, "Exceeded maximum CryptoDevs Supply");
        require(msg.value >= _price, "Ether sent is not correct");

        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);

    }
    
    // overriding existing baseURI of openzepellin
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;

    }

    function _setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send ether");
    }
}