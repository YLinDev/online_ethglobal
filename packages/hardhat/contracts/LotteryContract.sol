pragma solidity ^0.8.17;

// Import necessary OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LotteryContract is ERC721Enumerable, Ownable {
    uint public lotteryId;
    uint public lotteryEndTime; // Timestamp for the end of the lottery period
    mapping(uint => address) public lotteryHistory;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        lotteryId = 1;
        lotteryEndTime = block.timestamp + 5 minutes; // Set the end time 3 days from deployment
    }

    function getPotBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner(), block.timestamp)));
    }

    function pickWinner() public payable {
        require(block.timestamp >= lotteryEndTime, "Lottery period has not ended yet");
        require(totalSupply() > 0, "No participants to pick a winner");

        uint index = getRandomNumber() % totalSupply();
        address winner = ownerOf(index);
        payable(winner).transfer(address(this).balance);

        // Reset contract state
        lotteryId++;

        // Update the winner's history
        lotteryHistory[lotteryId] = winner;

        // Reset the lottery end time for the next round
        lotteryEndTime = block.timestamp + 3 days;
    }

    function enterLotto() public payable {
        require(block.timestamp < lotteryEndTime, "Lottery entry period has ended");
        require(msg.value >= 0.000000000001 ether, "Insufficient funds, must be greater than or equal to 0.000000000001 ETH");

        // Mint NFT to the user
        uint256 tokenId = totalSupply() + 1;
        _mint(msg.sender, tokenId);
    }
}
