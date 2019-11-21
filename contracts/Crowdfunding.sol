pragma solidity 0.5.13;
import 'https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol';

contract Crowdfunding {
    using SafeMath for uint256;

    Campaign[] private campaign;

    // Evento para criação de nova campanha
    event CampaignStarted(
        address coAddress,
        address ownerAdress,
        
        uint256 deadline,
        uint256 goalAmount,
     
        string campaignTitle,
        string campaignDesc
        
    );

    function startCampaign(
        string calldata title,
        string calldata description,
        uint durationInDays,
        uint amountToRaise
    ) external 
    {
        uint raiseUntil = now.add(durationInDays.mul(1 days));
        Campaign newCampaign = new Campaign(msg.sender, title, description, raiseUntil, amountToRaise);
        campaign.push(newCampaign);
        emit CampaignStarted(
            address(newCampaign),
            msg.sender,
            raiseUntil,
            amountToRaise,
            title,
            description
        );
    }                                                                                                                                   

    //Retornar campanhas existentes
    function returnAllCampaigns() external view returns(Campaign[] memory)
    {
        return campaign;
    }
}


contract Campaign 
    {
    using SafeMath for uint256;
    enum State 
    {
        Fundraising,
        Expired,
        Complete
    }

    address payable public owner;
    address Carlos;
    address Gabriel;
    
    string public title;
    string public description;
    
    uint256 public currentBalance;
    uint public goal;
 
    uint public completionDate;
    uint public campaignDeadline;
    uint public totalDonations;

    State public state = State.Fundraising;
    mapping (address => uint) public contributions;

    uint public voteCount;
    bool public votingApproved;

    event FundingReceived(address contributor, uint amount, uint currentTotal);
    event ownerPaid(address recipient);


    modifier inState(State _state)
    {
        require(state == _state);
        _;
    }

    modifier isowner() 
    {
        require(msg.sender == owner);
        _;
    }

    constructor
    (
        address payable campaignOwner,
        
        string memory campaignTitle,
        string memory campaignDesc,
        
        uint fundRaisingDeadline,
        uint goalAmount
        
    ) public
    {
        owner = campaignOwner;

        Carlos = 0x5600979d097F741c573d46EDb9cABfC75bB566AF;
        Gabriel = 0x7FFf406d6CA0e40d02112509E2472cB780fCbf88;
        
        title = campaignTitle;
        description = campaignDesc;
        
        goal = goalAmount;
        campaignDeadline = fundRaisingDeadline;
        currentBalance = 0;

        votingApproved = false;
        voteCount = 0;

        totalDonations = 0;
    }

    //Contribuir para a campanha
    function contribute() external inState(State.Fundraising) payable 
    {
        require(msg.sender != owner);
        
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        currentBalance = currentBalance.add(msg.value);
        totalDonations += 1;
        emit FundingReceived(msg.sender, msg.value, currentBalance);
        
        checkCompletion();
    }

    function vote() public
     {
         require(votingApproved == false);
         require(msg.sender == Carlos || msg.sender == Gabriel);
         voteCount += 1;
         if(voteCount == 2)
         {
             votingApproved = true;
         }
     }

    //Checkout do owner
    function payOut() internal inState(State.Complete) returns (bool) 
    {
        uint256 totalRaised = currentBalance;
        currentBalance = 0;

        if (owner.send(totalRaised)) 
        {
            emit ownerPaid(owner);
            return true;
        } else 
        {
            currentBalance = totalRaised;
            state = State.Complete;
        }

        return false;
    }
    
        function checkCompletion() public 
    {
        if (currentBalance >= goal)
        {
            state = State.Complete;
            payOut();
        } 
        else if (now > campaignDeadline) 
        {
            state = State.Expired;
        }
        completionDate = now;
    }

    
    //No caso da campanha expirar, refund do valor doado
    function getRefund() public inState(State.Expired) returns (bool)
    {
        require(contributions[msg.sender] > 0);

        uint amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;

        if (!msg.sender.send(amountToRefund))
        {
            contributions[msg.sender] = amountToRefund;
            return false;
        } else 
        {
            currentBalance = currentBalance.sub(amountToRefund);
        }

        return true;
    }

    function getRefundFundRaising() public inState(State.Fundraising) returns (bool)
    {
        require(contributions[msg.sender] > 0);
        
        uint256 amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;

        if (msg.sender.send(amountToRefund)) 
        {
            currentBalance = currentBalance.sub(amountToRefund);
            emit ownerPaid(msg.sender);
            return true;
        } else 
        {
            contributions[msg.sender] = amountToRefund;
            
        }

        return false;
    }

    function getDetails() public view returns 
    (
        address payable campaignOwner,
        
        string memory campaignTitle,
        string memory campaignDesc,
        
        uint256 currentAmount,
        uint256 goalAmount,
        
        uint256 deadline,
        State currentState,

        bool approved,
        uint256 voteCounter,

        uint campaignDonators

    ) {
        campaignOwner = owner;
        campaignTitle = title;
        campaignDesc = description;
        deadline = campaignDeadline;
        currentState = state;
        currentAmount = currentBalance;
        goalAmount = goal;
        approved = votingApproved;
        voteCounter = voteCount;
        campaignDonators = totalDonations;
    }
}
