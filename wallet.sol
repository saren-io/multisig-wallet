pragma solidity 0.7.5;
pragma abicoder v2;

contract Wallet {

    // Owners who can approve
    address[] public owners;
    // Approvals needed
    uint limit;
    // Store balance
    uint public balance;

    // Initialise owners and limit
    constructor(address[] memory _owners, uint _limit){
        owners = _owners;
        limit = _limit;
        balance = 0;
    }

    modifier onlyOwner{
        bool owner = false;
        // Loop through owners
        for (uint i = 0; i < owners.length; i++) {
            // Check if sender is an owner
            if (owners[i] == msg.sender) {
                owner = true;
            }
        }
        require(owner == true);
        _;
    }

    // Transfer objects for reference
    struct Transfer {
        uint id;
        uint approvals;
        uint amount;
        address payable to;
        bool sent;
    }

    event RequestCreated(uint _id, uint _amount, address _initiator, address _recipient);
    event ApprovalReceived(uint _id, uint _approvals, address _approver);
    event Approved(uint _id);

    // Array to store transfers
    Transfer[] requests;

    // Store approved transactions
    mapping(address => mapping(uint => bool)) approvals;

    // Approve transfer requests
    function approve(uint _index) public onlyOwner {
        // Check request not already approved
        require(approvals[msg.sender][_index] == false);
        // Check request not already sent
        require(requests[_index].sent == false);
        // Sign transaction from the matched owner
        approvals[msg.sender][_index] = true;
        requests[_index].approvals++;

        emit ApprovalReceived(_index, requests[_index].approvals, msg.sender);
        // Check if approvals reached
        if (requests[_index].approvals >= limit) {
            send(_index);
        }
    }

    // Function to send funds once approved
    function send(uint _index) private {
        requests[_index].sent = true;
        requests[_index].to.transfer(requests[_index].amount);

        emit Approved(_index);
    }

    // Deposit funds to the address
    function deposit() public payable {
        balance += msg.value;
    }

    // Get all transfer requests
    function getRequests() public view returns (Transfer[] memory){
        return requests;
    }

    // Only owners able to create transfers
    function request(uint _amount, address payable _to) public onlyOwner {
        require(balance >= _amount);
        requests.push(Transfer(requests.length, 0, _amount, _to, false));

        emit RequestCreated(requests.length, _amount, msg.sender, _to);
    }
}