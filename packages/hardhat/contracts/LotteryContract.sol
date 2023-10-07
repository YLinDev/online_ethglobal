pragma solidity ^0.8.17;

contract LotteryContract {
    address public owner;

    uint public lotteryId;

    address payable[] public players;

    mapping(uint => address payable)  public  lotteryHistory;

    constructor() {
        owner = msg.sender;
        lotteryId = 1;
    }

    function getPotBalence() public view returns(uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns(address payable[] memory){
        return players;
    }

    // gotta pay to enter;
    function enterLotto() public payable {
        players.push(payable(msg.sender));
        require(msg.value >= .000000000001 ether, "Insufficient funds must be greater then >= 000000000001 eth");
    }

    function getRandomNumber()  public view returns(uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }



    function pickWinner() public onlyOwner {
        uint index = getRandomNumber() % players.length;
        players[index].transfer(address(this).balance);

        //reset contract state

        players = new address payable[](0);

        lotteryId++; // updates the lottery id
        lotteryHistory[lotteryId] = players[index]; // updates the winners logs who won in the past
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }


}