// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Lottery {
    // Event declarations
    event LotteryEntered(address indexed participant, uint amount);



    // state variables:
    address public owner;
    address payable[] public players;
    uint public lotteryId;
    uint public lotteryEndTime;
    mapping (uint => address payable) public lotteryHistory;

    constructor() {
        owner = msg.sender;
        lotteryId = 1;
        // Set the lottery end time to 1 week from deployment
        lotteryEndTime = block.timestamp + 1 weeks;
    }



    // function for not waiting the 1week THIS IS ONLY FOR TESTING PURPOSES:
     function setLotteryEndTime(uint newEndTime) public onlyowner {
        lotteryEndTime = newEndTime;
     }




    // Get lotteryEndTime in readable numbers
    function getTimeLeft() public view returns (uint daysLeft, uint hoursLeft, uint minutesLeft) {
        uint timeRemaining = lotteryEndTime - block.timestamp;
        daysLeft = timeRemaining / 1 days;
        hoursLeft = (timeRemaining % 1 days) / 1 hours;
        minutesLeft = (timeRemaining % 1 hours) / 1 minutes;

        return (daysLeft, hoursLeft, minutesLeft);
    }

    function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function enterLottery() public payable {
        // require that after 1 week players can no longer enter to this lottery
        require(block.timestamp < lotteryEndTime, "Lottery entry period has ended, Please enter current/new one");
        require(msg.value > .01 ether);

        // address of player entering lottery
        players.push(payable(msg.sender));

        // Emit the LotteryEntered event
        emit LotteryEntered(msg.sender, msg.value);


    }

    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    /*
    This pickWinner() function has the endTime modifier
    which allows to pick the winner after the lottery ends
    */
    function pickWinner() public onlyowner endTime {
        uint index = getRandomNumber() % players.length;
        players[index].transfer(address(this).balance); 
        lotteryHistory[lotteryId] = players[index];
        lotteryId++;

        // reset the state of the contract
        players = new address payable[](0);

    }
     /*automatically reset the contract for the next round at a predefined interval,
      you can add a reset function that can only be triggered after a specified duration:
     */
    function resetLottery() public onlyowner {
    require(block.timestamp > lotteryEndTime + 1 weeks, "Time not elapsed for reset");

     
    }
    // Modifier 1.
    modifier onlyowner() {
      require(msg.sender == owner);
      _;
    }

    // Modifier 2.
    modifier endTime() {
        require(block.timestamp > lotteryEndTime, "Lottery period has not ended yet");
        _;
    }
}