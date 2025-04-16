// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.20;

contract MyTimelock {
    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    uint public constant GRACE_PERIOD = 14 days; 
    uint public constant MINIMUM_DELAY = 2 days;
    uint public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;

    mapping (bytes32 => bool) public queuedTransactions;

    constructor(address admin_, uint delay_) {
        require(delay_ >= MINIMUM_DELAY, "Delay must exceed minimum.");
        require(delay_ <= MAXIMUM_DELAY, "Delay must not exceed maximum.");
        admin = admin_;
        delay = delay_;
    }

    receive() external payable {}
    fallback() external payable {}

    function setDelay(uint delay_) external {
        require(msg.sender == address(this), "Only timelock can call.");
        require(delay_ >= MINIMUM_DELAY, "Delay too short.");
        require(delay_ <= MAXIMUM_DELAY, "Delay too long.");
        delay = delay_;
        emit NewDelay(delay);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "Only pendingAdmin can call.");
        admin = msg.sender;
        pendingAdmin = address(0);
        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) external {
        require(msg.sender == address(this), "Only timelock can call.");
        pendingAdmin = pendingAdmin_;
        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "Only admin can queue.");
        require(eta >= block.timestamp + delay, "ETA must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public {
        require(msg.sender == admin, "Only admin can cancel.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public payable returns (bytes memory) {
        require(msg.sender == admin, "Only admin can execute.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Transaction not queued.");
        require(block.timestamp >= eta, "Too early to execute.");
        require(block.timestamp <= eta + GRACE_PERIOD, "Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);
        return returnData;
    }
}
