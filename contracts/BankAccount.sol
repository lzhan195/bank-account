// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <=0.8.19;

contract BankAccount {
    event Deposit(
        address indexed user,
        uint indexed accountId,
        uint value,
        uint timestamp
    );
    event WithdrawRequested(
        address indexed user,
        uint indexed accountId,
        uint indexed withdrawId,
        uint amount,
        uint timeStamp
    );
    event Withdraw(uint indexed withdrawId, uint timestamp);
    event AccountCreated(address[] owners, uint indexed id, uint timestamp);

    struct WithdrawRequest {
        address user;
        uint amount;
        uint approvals;
        mapping(address => bool) ownersApproved;
        bool approved;
    }

    struct Account {
        address[] owner;
        uint balance;
        mapping(uint => WithdrawRequest) WithdrawRequests;
    }

    mapping(uint => Account) accounts;
    mapping(address => uint[]) userAccounts;

    uint nextAccountId;
    uint nextWithdrawId;

    function deposit(uint accountId) external payable {}

    function createAccount(address[] calldata otherOwners) external {}

    function requestWithdrawl(uint accountId, uint amount) external {}

    function approveWithdrawl(uint accountId, uint withdrawId) external {}

    function withdraw(uint accountId, uint withdrawId) external {}

    function getBalance(uint accountId) public view returns (uint) {}

    function getOwner(uint accountId) public view returns (address[] memory) {}

    function getApprovals(
        uint accountId,
        uint withdrawId
    ) public view returns (uint) {}

    function getAccounts() public view returns (uint[] memory) {}
}
