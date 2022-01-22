// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../node_modules/@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

struct issueProposal {
    uint approvedAmount;
    uint tokenAmount;
}

struct redeemProposal {
    uint approvedAmount;
    uint[] burnList;
}


contract Stock is ERC721PresetMinterPauserAutoId {

    mapping(address => mapping(uint => bool)) public isVoted;
    mapping(address => bool) public isBoardMember;
    mapping(uint => issueProposal) public issueProposals;
    mapping(uint => redeemProposal) public redeemProposals;
    uint boardMemberNum = 0;
    address root;
    uint proposalAmount = 0;
    
    constructor(string memory companyName, string memory symbol, string memory baseURL) 
    ERC721PresetMinterPauserAutoId(companyName, symbol, baseURL)  
    {
        root = msg.sender;
    }

    function getBoardMemberNum() external view returns (uint) {
        return boardMemberNum;
    }

    function getProposalAmount() external view returns (uint) {
        return proposalAmount;
    }

    modifier onlyRoot() {
        require(root == msg.sender, "Caller is not the root");
        _;
    }

    modifier onlyBoardMember() {
        require(isBoardMember[msg.sender], "Caller is not the boardMember");
        _;
    }

    function addBoardMembers(address[] calldata members) external onlyRoot {
        for (uint i = 0; i < members.length; i++) {
            isBoardMember[members[i]] = true;
            boardMemberNum++;
        }
    }

    function removeBoardMembers(address[] calldata members) external onlyRoot {
        for (uint i = 0; i < members.length; i++) {
            isBoardMember[members[i]] = false;
            boardMemberNum--;
        }
    }

    function issue(uint tokenAmount) external onlyBoardMember returns (uint) {
        issueProposals[proposalAmount] = issueProposal(0, tokenAmount);
        return proposalAmount++;
    }

    function reissue(uint tokenAmount) external onlyBoardMember returns (uint) {
        issueProposals[proposalAmount] = issueProposal(0, tokenAmount);
        return proposalAmount;
    }

    function redeem(uint[] calldata burnList) external onlyBoardMember returns (uint) {
        redeemProposals[proposalAmount] = redeemProposal(0, burnList);
        return proposalAmount++;
    }

    function issueApprove(uint proposalID) external onlyBoardMember {
        require(!isVoted[msg.sender][proposalID], "You have voted!");
        isVoted[msg.sender][proposalID] = true;
        issueProposals[proposalID].approvedAmount += 1;
    }

    function redeemApprove(uint proposalID) external onlyBoardMember {
        require(!isVoted[msg.sender][proposalID], "You have voted!");
        isVoted[msg.sender][proposalID] = true;
        redeemProposals[proposalID].approvedAmount += 1;
    }

    function confirmIssue(uint proposalID) external onlyBoardMember {
        require(issueProposals[proposalID].approvedAmount == boardMemberNum, "not all voted yet");
        uint mintAmount = issueProposals[proposalID].tokenAmount;
        for (uint i = 0; mintAmount > 0; i++) {
            if (_exists(i))
                continue;
            _mint(msg.sender, i);
            mintAmount -= 1;
        }
    }

    function confirmRedeem(uint proposalID) external onlyBoardMember {
        require(redeemProposals[proposalID].approvedAmount == boardMemberNum, "not all voted yet");
        for (uint i = 0; i < redeemProposals[proposalID].burnList.length; i++)
            burn(redeemProposals[proposalID].burnList[i]);
    }

}