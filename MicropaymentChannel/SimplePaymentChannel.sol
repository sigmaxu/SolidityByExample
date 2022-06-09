pragma solidity >=0.7.0 <0.9.0;

contract SimplePaymentChannel {
    address payable public sender;
    address payable public recipient;
    uint256 public expiration;

    constructor (address payable recipientAddress, uint duration) 
        public 
        payable
    {
        sender = payable(msg.sender);
        recipient = recipientAddress;
        expiration = block.timestamp + duration;
    }

    function isValidSignature(uint amount, bytes memory signature) 
        internal
        view
        returns (bool)
    {
        bytes32 message = prefixed(keccak256(abi.encodePacked(this, amount)));
        return recoverSigner(message, signature) == sender;
    }

    function close(uint amount, bytes memory signature) external {
        require(msg.sender == recipient);
        require(isValidSignature(amount, signature));
        recipient.transfer(amount);
        selfdestruct(sender);
    }

    function extend(uint newExpiration) external {
        require(msg.sender == sender);
        require(newExpiration > expiration);
        expiration = newExpiration;
    }

    function claimTimeOut() external {
        require(block.timestamp >= expiration);
        selfdestruct(sender);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig,96)))
        }
        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}