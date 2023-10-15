//SPDX-License-Indetifier: MIT

pragma solidity ^0.8.17;

// Import necessary OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract LotteryContract is ERC721Enumerable, Ownable, VRFConsumerBase {
    // VRF Chainlink variables:
    bytes32 internal keyHash;
    uint256 internal fee;

    // Lottery variables:
    uint public lotteryId;
    uint public lotteryEndTime; // Timestamp for the end of the lottery period
    mapping(uint => address) public lotteryHistory;

    constructor(string memory name, string memory symbol, address vrfCoordinator, address linkToken, bytes32 _keyHash, uint256 _fee) ERC721(name, symbol) {
        // VRF Chainlink variables initialized
        keyHash = _keyHash;
        fee = _fee;

        // Lottery variables initialized
        lotteryId = 1;
        lotteryEndTime = block.timestamp + 5 minutes; // Set the end time 3 days from deployment

        // VRF Consumer Base instantiated
        VRFConsumerBase(vrfCoordinator, linkToken);
    }

    // The rest of your functions and logic remains unchanged.

    // Chainlink functions:
    // Function for requesting randomness
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");
        requestId = requestRandomness(keyHash, fee);
        return requestId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(msg.sender == vrfCoordinator, "Fulfillment only permitted by Coordinator");
        // Use the randomness to select the winner
        uint index = randomness % totalSupply();
        address winner = ownerOf(index);
        payable(winner).transfer(address(this).balance);

        // Reset contract state
        lotteryId++;

        // Update the winner's history
        lotteryHistory[lotteryId] = winner;

        // Reset the lottery end time for the next round
        lotteryEndTime = block.timestamp + 3 days;
    }

    // Lottery functions:
    function getPotBalance() public view returns (uint) {
        return address(this).balance;
    }

    function enterLotto() public payable {
        require(block.timestamp < lotteryEndTime, "Lottery entry period has ended");
        require(msg.value >= 0.000000000001 ether, "Insufficient funds, must be greater than or equal to 0.000000000001 ETH");

        // Mint NFT to the user
        uint256 tokenId = totalSupply() + 1;
        _mint(msg.sender, tokenId);
    }
}
