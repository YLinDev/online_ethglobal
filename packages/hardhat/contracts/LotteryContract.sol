pragma solidity ^0.8.17;

// Important Imports
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

//Error Handling(kevin):
error YOLORandomNFT_AllreadyInitialized();
error YOLORandomNFT_NeedMoreFunds();
error YOLORandomNFT_RangeOurOfBounds();
error YOLORandomNFT_TransferFailed();



contract LotteryContractNFT is ERC721Enumerable, Ownable , VRFConsumerBaseV2{
    // Lottery Variables
    uint public lotteryId;
    uint public lotteryEndTime; // Timestamp for the end of the lottery period
    mapping(uint => address) public lotteryHistory;


    //NFT attributes/ whatever we decide to give(KEVIN)
    enum Attributes{
        hat, // 0
        glasses, // 1
        shoeType // 2
    }


    // Chainlink VRF Variables:
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_suscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;


    //NFT Variables:
    uint256 private immutable i_mintFee;
    uint256 private s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_nftTokenUri;
    bool private s_initialized;


     // Events
    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(Attributes attributes, address minter);

    // Helpers:
    mapping(uint => address) public s_requestIdToSender;


    constructor(
        string memory name, 
        string memory symbol,
        address vrfCoordinatorV2,
        uint64 suscriptionId,
        bytes32 gasLane,
        uint256 mintFee,
        uint32 callbackGasLimit,
        string[3] memory nftTokenUri) ERC721(name, symbol) {
        VRFConsumerBaseV2(vrfCoordinatorV2);
        ERC721("YOLO NFT", "YLN");
        // variables initialized drom chainlink specifications
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_suscriptionId = suscriptionId;
        i_mintFee = mintFee;
        i_callbackGasLimit = callbackGasLimit;
        _initializeContract(nftTokenUris);
        s_tokenCounter = 0;
        
        // Lottery Variables
        lotteryId = 1;
        lotteryEndTime = block.timestamp + 5 minutes; // Set the end time 3 days from deployment
    }

    // Chainlink RANDOMNESS functions for the NFT
    function requestNFT()public payable returns(uint256 requestId){
        if(msg.value < i_mintFee){
            revert YOLORandomNFT_NeedMoreFunds();
        }
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_suscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        s_requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
    }


      function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override
    {
        address nftOwner = s_requestIdToSender[requestId];
        uint256 newItemId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
        Attributes nftAttributes = getBreedFromModdedRng(moddedRng);
        _safeMint(nftOwner, newItemId);
        _setTokenURI(newItemId, s_nftTokenUri[uint256(nftAttributes)]);

    }

    // create a function that tells us how likely we are going to get the NFT.
    
    function getChance() public pure returns(uint256[3] memory){
         return [20, 50, MAX_CHANCE_VALUE];

    }

    function getAttributeFromRG() public pure returns(Attributes){
        uint256 totalSum = 0;
        uint256[3] memory chanceArr = getChance();
        // for loop
        for (uint256 i = 0; i < chanceArr.length; ++i) {

         if (moddedRng >= totalSum && moddedRng < chanceArr[i]) {
             return Attributes(i);
    }
        totalSum += chanceArr[i];

        }
        revert YOLORandomNFT_RangeOurOfBounds();
    }



    // getters for the NFT
     function getNftTokenUris(uint256 index) public view returns (string memory){
        return s_nftTokenUris[index];
    }

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function getNftTokenYolo(uint256 index) public view returns(string memory){
        return s_nftTokenUri[index];
    }

    function getInitialized() public view returns (bool) {
        return s_initialized;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }







    //Lottery Functions
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