// SPDX-License-Identifier: MIT

pragma solidity >0.4.1 <= 0.9.0;

// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol';

interface IERC20 {

    function getSupply() external  view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function returnAllowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract tokenLocker {
    string name = 'locker';
    string symbol = 'LOCK';
    uint8 decimal = 18;
    uint totalSupply = 10000000000000000000 * 10 ** 18;

    mapping(address => uint) public holdersRecord;
    mapping(address => mapping(address => uint)) public allowances;

    address protocol;
    constructor() {
        holdersRecord[msg.sender] = totalSupply;
        protocol = msg.sender;
    }

    function getSupply() external  view returns(uint) {
        return totalSupply;
    }

    function balanceOf(address holder) external  view returns(uint) {
        return holdersRecord[holder];
    }

    function transfer(address recipent, uint amountToSend) external  returns(bool)  {
        require(holdersRecord[msg.sender] >= amountToSend);
        holdersRecord[recipent] =  holdersRecord[recipent] + amountToSend;
        holdersRecord[msg.sender] =  holdersRecord[msg.sender] - amountToSend;
        return true;
    }
    function getBal() external view returns(uint) {
        return holdersRecord[msg.sender];
    }

    function approve(address spender, uint allowanceAmount) external  returns(bool) {
        address owner = msg.sender;
        allowances[owner][spender] = allowanceAmount;
        return true;
    }

    function returnAllowance(address owner, address spender) external  view returns(uint) {
        return allowances[owner][spender];
    }

    function transferFrom(address from, address to, uint transferAmount) external  returns(bool) {
        address spender = msg.sender;
        spendAllowance(from, spender, transferAmount);
        holdersRecord[to] = holdersRecord[to] + transferAmount;
        holdersRecord[from] =  holdersRecord[from] - transferAmount;
        return true;
    }

    function spendAllowance(address owner, address spender, uint allowanceAmount) internal view {
        uint allowanceBalance = allowances[owner][spender];
        require(allowanceBalance >= allowanceAmount);
        allowanceBalance = allowanceBalance - allowanceAmount;
    }

    mapping(address => uint) public lockedTokens;
    mapping(address => bool) lockersCondition;

    function lockToken(IERC20 token, uint amount) external {
        lockedTokens[msg.sender] = lockedTokens[msg.sender] + amount;
        holdersRecord[protocol] = holdersRecord[protocol] - amount;
        lockersCondition[msg.sender] = true;
        exchnageToken(token, amount, msg.sender);
    }
     function exchnageToken(IERC20 _token, uint amount, address accounts) internal {
        _token.transferFrom(accounts, protocol, amount);
        holdersRecord[accounts] = holdersRecord[accounts] + amount;
        lock(amount);
    }
    function lock(uint amount) internal {
        holdersRecord[msg.sender] = holdersRecord[msg.sender] - amount;
    }


    modifier onlyLockers()  {
        require(lockersCondition[msg.sender] == true);
        _;
    }

    function unLockToken(uint amount, IERC20 token0) external onlyLockers {
        require(lockedTokens[msg.sender] <= amount);
        lockedTokens[msg.sender] = lockedTokens[msg.sender] - amount;
        lockersCondition[msg.sender] = false;
        dexchnageToken(token0, amount, msg.sender);
    }

    function dexchnageToken(IERC20 _token, uint amount, address accounts) internal {
        _token.transferFrom(protocol, accounts, amount);
        holdersRecord[protocol] = holdersRecord[protocol] + amount;
    }


    function approve0(IERC20 token,uint amount) external {
        token.approve(protocol, amount);
    }

    
    mapping(address => uint) approvers;

}