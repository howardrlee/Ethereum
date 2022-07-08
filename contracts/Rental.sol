pragma solidity >=0.4.22 <0.9.0;

/**
 * @title  Rental
 * @author Howard R. Lee (howardrlee@yahoo.com)
 * @notice Used to track rental payments on the blockchain ledger
 *
 */
    /*
      "a70358fb5aba522f241eb69e2a626ee85d027851", "202201", "202201", "202201", 2100.53, "Kirk", "Main Street", "1", "1"
    */  


contract Rental {

    /** 
      * @author Howard R. Lee (howardrlee@yahoo.com)
      * @notice enum used in Rent object to identify a Rent instance as being CURRENT or LAGE
      */
    enum PaymentStatus {
        CURRENT,
        LATE
    }
    
  /** 
      * @author Howard R. Lee (howardrlee@yahoo.com)
      * @notice struct used to hold messages sent by the contract creator, each of which is sent as an event
      * @dev call getMessages to see the list of all messages sent by the contract creator
      * @param dateTime The dateTime that the message was added
      * @param message The message sent
      */
    struct Message {
        uint256 dateTime;
        string message;
    }

    /** 
      * @author Howard R. Lee (howardrlee@yahoo.com)
      * @notice struct used to as the Payment object to hold the values of any payment passed
      * @param  dateTime the dateTime the payment was sent
      * @param amount the amount, as a string, that was sent (note: if paymentTypeEther is true, this value will be an empty string)
      * @param paymentTypeEther true if the payment was sent as Ether and false if a payment "notification" was sent in the form of a string in the amount field
      * @param amountEther the Ether sent
      * @param sender the sender of the Payment instance
      */
    struct Payment {
        uint256 dateTime;
        string amount;
        bool paymentTypeEther;
        uint amountEther;
        address sender;
    }

    /** 
      * @author Howard R. Lee (howardrlee@yahoo.com)
      * @notice struct used to create an instance of a Rent object. The assumption here is that each Rent instance is unique and cryptologic hash is used when calling addTenantRent 
      * @param yearMonth the year and month of the Rent object instance
      * @param dueDate due date
      * @param gracePeriodDate grace period date...the assumption is that payment received after this date are considered late
      * @param amount the amount of the rent due if paid on time
      * @param tenant the name of the tenant...assumed to be free form text
      * @param propertyAddress the property address...assumed to be free form text
      * @param tenantId cryptologically hashed tenant name if we do not want the tenant name to be displayed
      * @param propertyAddressId cryptologically hashed property address if we do not want the property address to be displayed
      * @param paymentInstances we just track the number of instances of Payments received...This works in conjunction with the payments mapping obkect
      * @param initialized ensures that the each Rent "id" is unque. There is a modifier that ensures this will be the case.
      * @param owner the owner that created this Rent object
      * @param paymentStatus enum @PaymentStatus
      * @param payments map of Payment instances
      */
    struct Rent {
        string yearMonth;
        string dueDate;
        string gracePeriodDate;
        string amount;
        string tenant; // tenant name
        string propertyAddress;
        string tenantId; //unique id assigned to the tenant
        string propertyAddressId; // unique id assigned to the address
        uint256[] paymentInstances;
        uint256 initialized;
        address owner;
        PaymentStatus paymentStatus;
        mapping(uint256 => Payment) payments; // date and amount
    }

    /** 
      * @author Howard R. Lee (howardrlee@yahoo.com)
      * @notice struct similar to the Rent object from which it is modeled but sans the mapping of payments
      * @param rentInstanceId the rent instance id of this Rent object
      * @param yearMonth the year and month of the Rent object instance
      * @param dueDate due date
      * @param gracePeriodDate grace period date...the assumption is that payment received after this date are considered late
      * @param amount the amount of the rent due if paid on time
      * @param tenant the name of the tenant...assumed to be free form text
      * @param propertyAddress the property address...assumed to be free form text
      * @param tenantId cryptologically hashed tenant name if we do not want the tenant name to be displayed
      * @param propertyAddressId cryptologically hashed property address if we do not want the property address to be displayed
      * @param paymentInstances we just track the number of instances of Payments received...This works in conjunction with the payments mapping obkect
      * @param initialized ensures that the each Rent "id" is unque. There is a modifier that ensures this will be the case.
      * @param owner the owner that created this Rent object
      * @param paymentStatus enum @PaymentStatus
      */
    struct RentLite {
        string rentInstanceId;
        string yearMonth;
        string dueDate;
        string gracePeriodDate;
        string amount;
        string tenant; // tenant name
        string propertyAddress;
        string tenantId; //unique id assigned to the tenant
        string propertyAddressId; // unique id assigned to the address
        uint256[] paymentInstances;
        uint256 initialized;
        address owner;
        PaymentStatus paymentStatus;
    }

    /** 
      * @notice contract creation dateTime (instance variable)
    */
    uint256 contractCreatedDate;

    /** 
      * @notice author information about the underlying contract
    */
    string author = "@Author Howard R. Lee President-CEO http://www.affinityiq.com Affinity Systems, Inc. howardrlee@yahoo.com";

    
    /** 
      * @notice modifier that ensures that Rent objects remain unique
    */
    modifier onlyUniqueRenter(string memory rentInstanceId) {
        require(
            rentMap[rentInstanceId].initialized == 0,
            "Resident profile may already exist."
        );
        _;
    }

    /** 
      * @notice modifier that ensures that only the contract creator can access the modified function
    */
    modifier onlyOwner() {
        require(owner == msg.sender, "Unknown failure");
        _;
    }

    /** 
      * @notice modifier that ensures that a payment sent in is greater than zero
    */
    modifier onlyWithPayment(uint amount) {
        require(amount > 0, "An ETH greater than zero is required.");
        _;
    }

    /** 
      * @notice modifier that ensures that either the Rent instance creator or the contract owner are only able to access that Rent instance
    */
    modifier onlyOwnerOrAuthor(string memory rentInstanceId) {
        require(
            owner == msg.sender || rentMap[rentInstanceId].owner == msg.sender,
            "Unknown failure"
        );
        _;
    }

    /** 
      * @notice array of all rentIds
    */
    string[] rentIds;

    /** 
      * @notice a map of all Rent objects
    */
    mapping(string => Rent) rentMap;

    /** 
      * @notice an array containing all of the messages sent in by the contract creator
    */
    Message[] messages;

    /** 
      * @notice used to add a status message to the array of messages. Contract clients can call @getMessages to retreive the list
      * @param messageIn the message sent in
      */
    function addMessage(string memory messageIn) public onlyOwner  {
        uint256 today = block.timestamp;
        Message memory message  = Message (today, messageIn);
        messages.push(message);
        emit StatusMessage(today, messageIn);
    }

    /** 
      * @notice used to return the list of messages passed in my the contract owner/creator/administrator
      * @return array of previously added messages
      */
    function getMessages() public view returns (Message[] memory) {
        return messages;
    }

    /** 
      * @notice returns the Rent instance given the unique rentInstanceId passed in when the Rent object was originally created.
      * @param rentInstanceId the unique rentInstanceId passed in when the Rent object was created
      * @return yearMonth the year and month of the Rent object instance
      * @return dueDate due date
      * @return gracePeriodDate grace period date...the assumption is that payment received after this date are considered late
      * @return amount the amount of the rent due if paid on time
      * @return tenant the name of the tenant...assumed to be free form text
      * @return propertyAddress the property address...assumed to be free form text
      * @return tenantId cryptologically hashed tenant name if we do not want the tenant name to be displayed
      * @return propertyAddressId cryptologically hashed property address if we do not want the property address to be displayed
      * @return paymentInstances we just track the number of instances of Payments received...This works in conjunction with the payments mapping obkect
      * @return paymentStatus enum @PaymentStatus
    */
    function getRentById(string memory rentInstanceId)
        public
        onlyWithPayment(msg.value)
        payable
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            PaymentStatus
        )
    {
        Rent storage rent = rentMap[rentInstanceId];
        return (
            rent.yearMonth,
            rent.dueDate,
            rent.gracePeriodDate,
            rent.amount,
            rent.tenant,
            rent.propertyAddress,
            rent.tenantId,
            rent.propertyAddressId,
            rent.paymentInstances.length,
            rent.paymentStatus
        );
    }

        /** 
      * @notice returns the Rent instance given the unique rentInstanceId passed in when the Rent object was originally created....accessible by contract creator only
      * @param rentInstanceId the unique rentInstanceId passed in when the Rent object was created
      * @return yearMonth the year and month of the Rent object instance
      * @return dueDate due date
      * @return gracePeriodDate grace period date...the assumption is that payment received after this date are considered late
      * @return amount the amount of the rent due if paid on time
      * @return tenant the name of the tenant...assumed to be free form text
      * @return propertyAddress the property address...assumed to be free form text
      * @return tenantId cryptologically hashed tenant name if we do not want the tenant name to be displayed
      * @return propertyAddressId cryptologically hashed property address if we do not want the property address to be displayed
      * @return paymentInstances we just track the number of instances of Payments received...This works in conjunction with the payments mapping obkect
      * @return paymentStatus enum @PaymentStatus
    */
    function getRentByIdExtended(string memory rentInstanceId)
        public
        view
        onlyOwner
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            PaymentStatus
        )
    {
        Rent storage rent = rentMap[rentInstanceId];
        return (
            rent.yearMonth,
            rent.dueDate,
            rent.gracePeriodDate,
            rent.amount,
            rent.tenant,
            rent.propertyAddress,
            rent.tenantId,
            rent.propertyAddressId,
            rent.paymentInstances.length,
            rent.paymentStatus
        );
    }


    /** 
      * @notice returns all Rent instances
      * @return array of all Rent objects
    */
    function getAllRentObjects()
        public
        view
        onlyOwner
        returns (RentLite[] memory)
    {
        uint256 count = rentIds.length;
        RentLite[] memory rentArray = new RentLite[](count);

        for (uint256 i = 0; i < count; i++) {
            Rent storage rent = rentMap[rentIds[i]];
            RentLite memory rl = RentLite({
                rentInstanceId: rentIds[i],
                yearMonth: rent.yearMonth,
                dueDate: rent.dueDate,
                gracePeriodDate: rent.gracePeriodDate,
                amount: rent.amount,
                tenant: rent.tenant,
                propertyAddress: rent.propertyAddress,
                tenantId: rent.tenantId,
                propertyAddressId: rent.propertyAddressId,
                paymentInstances: rent.paymentInstances,
                initialized: rent.initialized,
                owner: rent.owner,
                paymentStatus: rent.paymentStatus
            });
            rentArray[i] = rl;
        }

        return rentArray;
    }


    /** 
      * @notice returns the list of rent payments for a given Rent instance (the rentInstanceId that was used to create instance should be passed in)
      * @param rentInstanceId the rentInstanceId that was passed in when the Rent instance was originally created.
      * @return payment array of Payment objects
    */
    function getRentPayments(string memory rentInstanceId)
        public
        onlyWithPayment(msg.value)
        payable
        returns (Payment[] memory)
    {
        uint256 count = rentMap[rentInstanceId].paymentInstances.length;
        Payment[] memory payments = new Payment[](count);

        for (uint256 i = 0; i < count; i++) {
            Payment memory payment = Payment({
                dateTime: rentMap[rentInstanceId].paymentInstances[i],
                amount: rentMap[rentInstanceId]
                    .payments[rentMap[rentInstanceId].paymentInstances[i]]
                    .amount,
                amountEther: rentMap[rentInstanceId]
                    .payments[rentMap[rentInstanceId].paymentInstances[i]]
                    .amountEther,
                paymentTypeEther: rentMap[rentInstanceId]
                    .payments[rentMap[rentInstanceId].paymentInstances[i]]
                    .paymentTypeEther,
                sender: rentMap[rentInstanceId]
                    .payments[rentMap[rentInstanceId].paymentInstances[i]]
                    .sender   
            });
            payments[i] = payment;
        }

        return payments;
    }

    /** 
      * @notice used to add an instance of a rent payment. Note: This is just a record and actual currency is not passed.
      * @param rentInstanceId the unique rentInstanceId used when the Rent object was created.
      * @param amount amount of rent payment as a string
    */
    function addRentPayment(string memory rentInstanceId, string memory amount)
        public
    {
        uint256 timestamp = block.timestamp;
        rentMap[rentInstanceId].paymentInstances.push(timestamp);
        rentMap[rentInstanceId].payments[rentMap[rentInstanceId].paymentInstances.length-1] = Payment({
            dateTime: timestamp,
            amount: amount,
            amountEther: 0,
            paymentTypeEther: false,
            sender: msg.sender    
        });
    }

    /** 
      * @notice used to add an instance of a rent payment while passing Ether
      * @param rentInstanceId the unique rentInstanceId used when the Rent object was created.
    */
    function addRentPaymentWithEth(string memory rentInstanceId)
        public onlyWithPayment(msg.value) payable
    {
        uint256 timestamp = block.timestamp;
        rentMap[rentInstanceId].paymentInstances.push(timestamp);
        rentMap[rentInstanceId].payments[timestamp] = Payment({
            dateTime: timestamp,
            amount: "",
            amountEther: msg.value,
            paymentTypeEther: true,
            sender: msg.sender
        });
    }

    /** 
      * @notice used by either the contract creator or Rent instance creator to update the Rent status to either CURRENT or LATE
      * @param rentInstanceId the unique rentInstanceId used when the Rent object was created.
      * @param paymentStatusIn payment status of 0 for CURRENT or 1 for LATE
    */
    function setRentPaymentStatus(string memory rentInstanceId, uint paymentStatusIn) public onlyOwnerOrAuthor(rentInstanceId) {
        rentMap[rentInstanceId].paymentStatus = (paymentStatusIn == 0) ? PaymentStatus.CURRENT : PaymentStatus.LATE;
    }

    /** 
      * @notice used to create a RENT instance
      * @param rentInstanceId a unique id for the RENT instance.
      * @param yearMonth the year and month of the Rent object instance
      * @param dueDate due date
      * @param gracePeriodDate grace period date...the assumption is that payment received after this date are considered late
      * @param amount the amount of the rent due if paid on time
      * @param tenant the name of the tenant...assumed to be free form text
      * @param propertyAddress the property address...assumed to be free form text
      * @param tenantId cryptologically hashed tenant name if we do not want the tenant name to be displayed
      * @param propertyAddressId cryptologically hashed property address if we do not want the property address to be displayed
      */
    function addTenantRent(
        string memory rentInstanceId,
        string memory yearMonth,
        string memory dueDate,
        string memory gracePeriodDate,
        string memory amount,
        string memory tenant,
        string memory propertyAddress,
        string memory tenantId,
        string memory propertyAddressId
    ) public onlyUniqueRenter(rentInstanceId) {
        Rent storage rent = rentMap[rentInstanceId];
        rent.amount = amount;
        rent.dueDate = dueDate;
        rent.gracePeriodDate = gracePeriodDate;
        rent.propertyAddress = propertyAddress;
        rent.propertyAddressId = propertyAddressId;
        rent.tenant = tenant;
        rent.tenantId = tenantId;
        rent.yearMonth = yearMonth;
        rent.initialized = 1;
        rent.paymentStatus = PaymentStatus.CURRENT;
        rent.owner = msg.sender;

        rentIds.push(rentInstanceId);
    }

    /** 
      * @notice event used for status messages sent in by contract creator
      * @param timestamp the timestamp the message was sent
      * @param message the message itself
      */
    event StatusMessage(uint256 timestamp, string message);

    /** 
      * @notice used to get the number of RENT objects created
      * @return the size of the rentMap that holds all of the RENT objects/instances
      */
    function getRentMapSize() public view onlyOwner returns (uint256) {
        return rentIds.length;
    }

    /** 
      * @notice contract creator
    */
    address owner;

    /** 
      * @notice constructor that captures both the contract creator as well as the timestamp the contract was created
    */
    constructor() public {

        owner = msg.sender;
        contractCreatedDate = block.timestamp;
    }

    /** 
      * @notice returns the profile of the contract creator
      * @return the profile, as a string, of the contract creator
      */
    function about() public view returns (string memory) {
        return author;
    }

    /** 
      * @notice returns the contract creation date....this is a convenience function, as the creation date is sitting on the blockchain
      * @return the contractor creation date
      */
    function getContractCreatedDate() public view returns (uint256) {
        return contractCreatedDate;
    }

    /** 
      * @notice sends the contract balance to the contract creator's account
    */
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /** 
      * @notice returns the address of the contract creator
      */
    function getOwner() public view onlyOwner returns (address) {
        return owner;
    }

    /** 
      * @notice fallback function
      */
    fallback() external payable {}

    /** 
      * @notice returns the current contract balance
      */
    function getBal() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }
}
