// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/*
      __ ______  ____  ____        __  __  
     / //_/ __ \/ __ \/ __ \ ___  / /_/ /_ 
    / ,< / / / / / / / /_/ // _ \/ __/ __ \
   / /| / /_/ / /_/ / _, _//  __/ /_/ / / /
  /_/ |_\____/_____/_/ |_(_)___/\__/_/ /_/ 
  
  @dev: kodr.eth
*/

contract Duel {
    address public initiator;
    address public secondUser;
    address public thirdParty;
    uint256 public lockedAmount;
    string public eventDescription;
    address public winner;
    bool public isResolved;
    bool public canceled;

    event BetConfirmed(address indexed user);
    event ThirdPartyAppointed(address indexed thirdParty);
    event BetResolved(address indexed winner, uint256 rewardAmount);
    event BetCanceled(address indexed user, uint256 refundAmount);

    modifier onlyInitiator() {
        require(msg.sender == initiator, "Only the initiator can call this function");
        _;
    }

    modifier onlyParticipants() {
        require(msg.sender == initiator || msg.sender == secondUser, "Only participants can call this function");
        _;
    }

    modifier onlyThirdParty() {
        require(msg.sender == thirdParty, "Only the third party can call this function");
        _;
    }

    constructor(
        address _secondUser,
        address _thirdParty,
        string memory _eventDescription,
        uint256 _lockedAmount,
        address _initiator
    ) {
        initiator = _initiator;
        secondUser = _secondUser;
        thirdParty = _thirdParty;
        eventDescription = _eventDescription;
        lockedAmount = _lockedAmount;
        isResolved = false;
        canceled = false;
    }

    function confirmBet() public payable onlyParticipants {
        require(msg.value == lockedAmount, "Locked amount must match the bet amount");
        emit BetConfirmed(msg.sender);
    }

    function appointThirdParty() public onlyInitiator {
        emit ThirdPartyAppointed(msg.sender);
    }

    function resolveBet(bool _initiatorWins) public onlyThirdParty {
        require(!isResolved, "The bet has already been resolved");
        require(!canceled, "The bet has been canceled");

        if (_initiatorWins) {
            winner = initiator;
        } else {
            winner = secondUser;
        }

        uint256 rewardAmount = address(this).balance;
        isResolved = true;
        payable(winner).transfer(rewardAmount);

        emit BetResolved(winner, rewardAmount);
    }

    function cancelBet() public onlyParticipants {
        require(!isResolved, "The bet has been resolved");
        require(!canceled, "The bet has already been canceled");

        uint256 refundAmount = address(this).balance;
        canceled = true;
        payable(msg.sender).transfer(refundAmount);

        emit BetCanceled(msg.sender, refundAmount);
    }
}


contract DuelFactory {
    address[] public deployedDuels;

    event DuelCreated(address indexed creator, address indexed duelContract);

    function createDuel(
        address _secondUser,
        address _thirdParty,
        string memory _eventDescription,
        uint256 _lockedAmount
    ) public {
        Duel newDuel = new Duel(_secondUser, _thirdParty, _eventDescription, _lockedAmount, msg.sender);
        deployedDuels.push(address(newDuel));
        emit DuelCreated(msg.sender, address(newDuel));
    }

    function getDeployedDuels() public view returns (address[] memory) {
        return deployedDuels;
    }
}