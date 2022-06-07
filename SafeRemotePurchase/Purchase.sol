pragma solidity ^0.8.13;

contract Purchase {
    uint public value;
    address payable public seller;
    address payable public buyer;

    enum State {
        Created,
        Locked,
        Release,
        Inactive
    }

    State public state;

    modifier condition(bool condition_) {
        require(condition_);
        _;
    }
    ///Only the buyer can call this function.
    error OnlyBuyer();
    ///Only the seller can call this function.
    error OnlySeller();
    ///The provided value has to be even.
    error ValueNotEven();
    ///The faction cannot be called at the current state.
    error InvalidState();

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this.");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this.");
        _;
    }

    modifier inState(State _state) {
        require(state == _state, "Invalid state.");
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SellerRefunded();

    constructor() payable {
        seller = payable(msg.sender);
        value = msg.value / 2;
        if ((2 * value) != msg.value)
            revert ValueNotEven();
    }

    function abort() external onlySeller inState(State.Created) {
        emit Aborted();
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }

    function confirmPurchase() external inState(State.Created) condition(msg.value == (2 * value)) payable {
        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        state = State.Locked;
    }

    function confirmReceived() external onlyBuyer inState(State.Locked) {
        emit ItemReceived();
        state = State.Release;
        buyer.transfer(value);
    }

    function refundSeller() external onlySeller inState(State.Release) {
        emit SellerRefunded();
        state = State.Inactive;
        seller.transfer(3 * value);
    }
}