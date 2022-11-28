//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

/*
1.The wallet has one owner
2.The wallet should be able to receive funds, no matter what
3.It is possible for the owner to spend funds on any kind of address, no matter if its a Externally Owned Account (EOA - with a private key), 
or a Contract Address.
4.It should be possible to allow certain people to spend up to a certain amount of funds.
5.It should be possible to set the owner to a different address by a minimum of 3 voters, in case funds are lost.
*/


contract sampleWallet{

    address  payable public owner;
    mapping(address => bool) public isAllowedToSend;   
    mapping(address => uint) public allowance;

    mapping(address => bool) public voter;
    address payable nextOwner;
    uint votersResetCount;
    uint public constant  noOfVotes = 3;

    mapping(address => mapping(address => bool)) nextOwnerVotedBool;

constructor() {
     owner  = payable(msg.sender);
}
function checkBalance() public view returns(uint) {
    return address(this).balance;
}

function  selectNewOwner (address payable _nextOwner) public {
    require(voter[msg.sender], "You are not on the voters list, Sorry");
    require(nextOwnerVotedBool[_nextOwner][msg.sender] == false, "You have already voted, aborting.."); // Default BOOL value is false
    if(nextOwner != _nextOwner) {
        nextOwner = _nextOwner;
        votersResetCount = 0;
    }

    nextOwnerVotedBool[_nextOwner][msg.sender] = true;
    votersResetCount ++;

    if(votersResetCount >= noOfVotes )  {
        owner = nextOwner;
        nextOwner = payable(address(0));
    }
}

function setAllowanceAndVoter(address _addr, uint _amount) public {

    require(msg.sender == owner, "You are not the owner");
    allowance[_addr] = _amount;
    isAllowedToSend[_addr]= true;
    voter[_addr] = true;
}

function  blacklist (address _addr) public {
    require(msg.sender == owner, "You dont have the permission to set the blacklist");
    isAllowedToSend[_addr] = false;
}


function transfer(address payable _to, uint _amount, bytes memory payload) public returns (bytes memory) {
    require (_amount <= address(this).balance, "Not Enough funds");
    if(msg.sender != owner)  {
        require(isAllowedToSend[msg.sender], "This wallet is not allowed to send ");
        require(allowance[msg.sender] >= _amount, "Amount is exceeding the limit set by the owner, aborting");
        allowance[msg.sender] -= _amount;
    }    

    (bool success, bytes memory  returnData) = _to.call{value : _amount}(payload);
    require(success, "Transaction failed");
    return returnData;
}

receive() external payable {}

}

contract consumer {
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function deposit()  public payable {}
}
