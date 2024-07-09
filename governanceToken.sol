// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GovernanceToken {
    string public name = "EDU";
    string public symbol = "EDU";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Proposals
    enum ProposalType { NewCourse, RewardAdjustment, Partnership, TechImprovement }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        ProposalType proposalType;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
        bool executed;
    }

    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public voted;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ProposalCreated(uint256 id, address proposer, string description, ProposalType proposalType, uint256 endTime);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, bool success);

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from], "Insufficient balance");
        require(_value <= allowance[_from][msg.sender], "Allowance exceeded");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function createProposal(string memory _description, ProposalType _proposalType, uint256 _duration) public returns (uint256) {
        uint256 proposalId = proposals.length;
        proposals.push(Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            proposalType: _proposalType,
            votesFor: 0,
            votesAgainst: 0,
            endTime: block.timestamp + _duration,
            executed: false
        }));
        emit ProposalCreated(proposalId, msg.sender, _description, _proposalType, block.timestamp + _duration);
        return proposalId;
    }

    function vote(uint256 _proposalId, bool _support) public {
        require(_proposalId < proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.endTime, "Voting period ended");
        require(!voted[_proposalId][msg.sender], "Already voted");

        voted[_proposalId][msg.sender] = true;
        if (_support) {
            proposal.votesFor += balanceOf[msg.sender];
        } else {
            proposal.votesAgainst += balanceOf[msg.sender];
        }
        emit Voted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) public {
        require(_proposalId < proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;
        bool success = proposal.votesFor > proposal.votesAgainst;
        emit ProposalExecuted(_proposalId, success);
    }

    function getProposal(uint256 _proposalId) public view returns (
        uint256 id,
        address proposer,
        string memory description,
        ProposalType proposalType,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 endTime,
        bool executed
    ) {
        require(_proposalId < proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.proposalType,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.endTime,
            proposal.executed
        );
    }
}
