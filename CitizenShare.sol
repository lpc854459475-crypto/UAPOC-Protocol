// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title UAPOC Citizen Share
 * @notice ERC-8004兼容的不可转让公民份额（Soulbound Token）
 * @dev 每位验证公民自动铸造一份，终身绑定
 */
contract CitizenShare is ERC721, Ownable {
    using ECDSA for bytes32;

    uint256 public totalCitizens;
    mapping(address => bool) public hasClaimed;
    string public constant VERSION = "UAPOC-v0.1-202603";

    constructor() ERC721("UAPOC Citizen Share", "UAPOC-CS") Ownable(msg.sender) {}

    // 公民验证后铸造（可由zk-PoP oracle调用）
    function claimCitizenShare(address to, bytes calldata signature) external {
        require(!hasClaimed[to], "Already claimed");
        // 简单签名验证（生产环境用ERC-8004标准oracle）
        bytes32 hash = keccak256(abi.encodePacked(to, "UAPOC-CITIZEN"));
        require(owner() == hash.recover(signature), "Invalid signature");

        uint256 tokenId = totalCitizens++;
        _safeMint(to, tokenId);
        hasClaimed[to] = true;
    }

    // Soulbound：不可转让
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        require(from == address(0) || to == address(0), "Soulbound: Non-transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // 仅用于UAPOC Treasury查询
    function getCitizenCount() external view returns (uint256) {
        return totalCitizens;
    }
}
