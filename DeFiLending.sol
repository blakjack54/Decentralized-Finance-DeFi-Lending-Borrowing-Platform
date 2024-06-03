// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeFiLending {
    struct Loan {
        address borrower;
        uint256 amount;
        uint256 interestRate;
        uint256 dueDate;
        bool repaid;
    }

    IERC20 public token;
    uint256 public totalDeposits;
    mapping(address => uint256) public deposits;
    mapping(address => Loan[]) public loans;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event LoanTaken(address indexed borrower, uint256 amount, uint256 interestRate, uint256 dueDate);
    event LoanRepaid(address indexed borrower, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
    }

    function deposit(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        deposits[msg.sender] += amount;
        totalDeposits += amount;
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function takeLoan(uint256 amount, uint256 interestRate, uint256 duration) external {
        require(totalDeposits >= amount, "Insufficient liquidity");
        uint256 dueDate = block.timestamp + duration;
        loans[msg.sender].push(Loan(msg.sender, amount, interestRate, dueDate, false));
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit LoanTaken(msg.sender, amount, interestRate, dueDate);
    }

    function repayLoan(uint256 loanIndex) external {
        Loan storage loan = loans[msg.sender][loanIndex];
        require(!loan.repaid, "Loan already repaid");
        require(block.timestamp <= loan.dueDate, "Loan overdue");

        uint256 repaymentAmount = loan.amount + (loan.amount * loan.interestRate / 100);
        require(token.transferFrom(msg.sender, address(this), repaymentAmount), "Transfer failed");

        loan.repaid = true;
        totalDeposits += loan.amount;
        emit LoanRepaid(msg.sender, repaymentAmount);
    }

    function getLoanDetails(address borrower, uint256 loanIndex) external view returns (uint256 amount, uint256 interestRate, uint256 dueDate, bool repaid) {
        Loan storage loan = loans[borrower][loanIndex];
        return (loan.amount, loan.interestRate, loan.dueDate, loan.repaid);
    }
}
