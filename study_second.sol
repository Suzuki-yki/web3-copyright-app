// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @title Digital Notary Service
 * @dev This contract allows users to register artwork hashes for copyright protection.
 * It demonstrates data storage, payment handling, and access control.
 */
contract digitalNotary {

    // Structure to store information about each registered artwork
    struct Record {
        address author;    // The wallet address of the copyright owner
        uint256 timestamp; // The exact block time the record was created
        string artName;    // The descriptive name of the artwork
    }
    
    // Mapping: Stores unique file hashes (bytes32) to their corresponding Records
    // Acts as a decentralized database
    mapping(bytes32 => Record) public Data;

    // Event: Emitted when a new work is registered. 
    // This allows front-end applications to "listen" for updates.
    event infor(bytes32 indexed hash, address author, string name);

    /**
     * @dev Registers a new artwork hash onto the blockchain.
     * @param _hash The unique SHA-256 hash representing the file.
     * @param _artName The name provided by the author.
     * Requires a payment of at least 0.01 ETH (or native chain token).
     */
    function uploadWork(bytes32 _hash, string memory _artName) public payable {
        // Validation: Ensure the user has sent at least 0.01 ether
        require(msg.value >= 0.01 ether, "Insufficient payment: 0.01 ETH required");
        
        // Validation: Ensure this specific hash has not been registered before
        require(Data[_hash].author == address(0), "Error: This artwork already exists on-chain");

        // Logic: Save the record to the permanent blockchain storage
        Data[_hash] = Record({
            author: msg.sender, 
            timestamp: block.timestamp,
            artName: _artName
        });

        // Log the registration for the front-end to detect
        emit infor(_hash, msg.sender, _artName);
    }

    // Address of the contract administrator (the person who deployed it)
    address public owner;

    /**
     * @dev Sets the contract deployer as the initial owner.
     */
    constructor() { 
        owner = msg.sender; 
    }

    /**
     * @dev Withdraws all accumulated funds from the contract to the owner's wallet.
     * Only accessible by the contract owner for security.
     */
    function withdraw() public {
        // Access Control: Only the owner can execute this function
        require(msg.sender == owner, "Security Error: Only owner can withdraw funds");
        
        uint256 amount = address(this).balance;

        // Check if there is any balance to withdraw
        require(amount > 0, "Error: No funds available for withdrawal");

        // Security: Transfer the balance using the low-level .call method (industry best practice)
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Withdrawal failed: Transfer error");
    }
}