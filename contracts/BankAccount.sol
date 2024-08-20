// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract BankAccount {
    event Deposit(
        address indexed user,
        uint256 indexed accountId,
        uint256 value,
        uint256 timestamp
    );
    event WithdrawRequested(
        address indexed user,
        uint256 indexed accountId,
        uint256 indexed withdrawId,
        uint256 amount,
        uint256 timeStamp
    );
    event Withdraw(uint256 indexed withdrawId, uint256 timestamp);
    event AccountCreated(
        address[] owners,
        uint256 indexed id,
        uint256 timestamp
    );

    struct WithdrawRequest {
        address user;
        uint256 amount;
        uint256 approvals;
        mapping(address => bool) ownersApproved;
        bool approved;
    }

    struct Account {
        address[] owners;
        uint256 balance;
        mapping(uint256 => WithdrawRequest) WithdrawRequests;
    }

    mapping(uint256 => Account) accounts;
    mapping(address => uint256[]) userAccounts;

    uint256 nextAccountId;
    uint256 nextWithdrawId;

    modifier accountOwner(uint256 _accountId) {
        bool isOwner;
        for (uint256 idx; idx < accounts[_accountId].owners.length; idx++) {
            if (accounts[_accountId].owners[idx] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "your are not an owner of this account!");
        _;
    }

    modifier validOwners(address[] calldata owners) {
        require(owners.length + 1 <= 4, "maximum of 4 owners per account");
        for (uint256 i; i < owners.length; i++) {
            for (uint256 j = i + 1; j < owners.length; j++) {
                if (owners[i] == owners[j]) {
                    revert("no duplicate owners");
                }
            }
        }
        _;
    }

    modifier sufficientBalance(uint256 _accountId, uint256 _amount) {
        require(
            accounts[_accountId].balance >= _amount,
            "insufficient balance"
        );
        _;
    }

    modifier canApprove(uint256 _accountId, uint256 _withdrawId) {
        require(
            !accounts[_accountId].WithdrawRequests[_withdrawId].approved,
            "this request is already approved"
        );
        require(
            accounts[_accountId].WithdrawRequests[_withdrawId].user !=
                msg.sender,
            "you cannot approve this request"
        );
        require(
            accounts[_accountId].WithdrawRequests[_withdrawId].user !=
                address(0),
            "this request does not exist"
        );
        require(
            !accounts[_accountId].WithdrawRequests[_withdrawId].ownersApproved[
                msg.sender
            ],
            "you have already approved this request"
        );
        _;
    }

    modifier canWithdraw(uint256 _accountId, uint _withdrawId) {
        require(
            accounts[_accountId].WithdrawRequests[_withdrawId].user ==
                msg.sender,
            "you did not create this requ"
        );
        require(
            accounts[_accountId].WithdrawRequests[_withdrawId].approved,
            "this request is not approved"
        );
        _;
    }

    function deposit(
        uint256 _accountId
    ) external payable accountOwner(_accountId) {
        accounts[_accountId].balance += msg.value;
    }

    function createAccount(
        address[] calldata otherOwners
    ) external validOwners(otherOwners) {
        address[] memory owners = new address[](otherOwners.length + 1);
        owners[otherOwners.length] = msg.sender;

        uint256 id = nextAccountId;

        for (uint256 idx; idx < owners.length; idx++) {
            if (idx < owners.length - 1) {
                owners[idx] = otherOwners[idx];
            }

            if (userAccounts[owners[idx]].length > 2) {
                revert("each user can have a max of 3 account!");
            }
            userAccounts[owners[idx]].push(id);
        }

        accounts[id].owners = owners;
        nextAccountId++;
        emit AccountCreated(owners, id, block.timestamp);
    }

    function requestWithdrawl(
        uint256 _accountId,
        uint256 _amount
    ) external accountOwner(_accountId) sufficientBalance(_accountId, _amount) {
        uint256 id = nextWithdrawId;
        WithdrawRequest storage request = accounts[_accountId].WithdrawRequests[
            id
        ];
        request.user = msg.sender;
        request.amount = _amount;
        nextWithdrawId++;
        emit WithdrawRequested(
            msg.sender,
            _accountId,
            id,
            _amount,
            block.timestamp
        );
    }

    function approveWithdrawl(
        uint256 _accountId,
        uint256 _withdrawId
    ) external accountOwner(_accountId) canApprove(_accountId, _withdrawId) {
        WithdrawRequest storage request = accounts[_accountId].WithdrawRequests[
            _withdrawId
        ];
        request.approvals++;
        request.ownersApproved[msg.sender] = true;

        if (request.approvals == accounts[_accountId].owners.length - 1) {
            request.approved = true;
        }
    }

    function withdraw(
        uint256 _accountId,
        uint256 _withdrawId
    ) external canWithdraw(_accountId, _withdrawId) {
        uint256 amount = accounts[_accountId]
            .WithdrawRequests[_withdrawId]
            .amount;
        require(accounts[_accountId].balance >= amount, "insufficient balance");

        accounts[_accountId].balance -= amount;
        delete accounts[_accountId].WithdrawRequests[_withdrawId];

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success);

        emit Withdraw(_accountId, block.timestamp);
    }

    function getBalance(uint256 _accountId) public view returns (uint256) {
        return accounts[_accountId].balance;
    }

    function getOwner(
        uint256 _accountId
    ) public view returns (address[] memory) {
        return accounts[_accountId].owners;
    }

    function getApprovals(
        uint256 _accountId,
        uint256 _withdrawId
    ) public view returns (uint256) {
        return accounts[_accountId].WithdrawRequests[_withdrawId].approvals;
    }

    function getAccounts() public view returns (uint256[] memory) {
        return userAccounts[msg.sender];
    }
}
