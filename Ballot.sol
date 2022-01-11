pragma solidity ^0.8.0;

contract Election {
    //This represents a single voter.
    struct Voter {
        bytes32 pubkey; //The public keys that the ring signatures are composed of
        uint prefix; //02 or 03
        uint center;
        bool hasCenter; //If true, this person has already entered a center
    }

    //A center with N voters
    struct Center {
        address cPerson; //Who send votes on behalf of voters
        uint category; //For statistics
        uint size; //Number of voters
    }

    //Ballot info
    struct Ballot {
        bytes32 id;
        bool closed; //If it is closed, no more interaction is possible
    }

    //This struct represents a vote containing a ring signature
    struct Vote {
        bytes32 voteHash; //A hash of the URS
        uint candidate; //The chosen candidate
    }

    //This is a type for a single candidate.
    struct Candidate {
        bytes32 candidateInfo; //Candidate info
        uint votesCount; //Number of accumulated votes
    }

    //The creator of the campaign
    address public nationalElectoralCouncil;

    //Centers that are composed of voters
    Center[] public centers;

    //All possible center categories
    bytes32[] public centerCategories;

    //Each ballot represents a round
    Ballot[] public ballots;

    //Voters, who must also be registered in centers
    mapping(address => Voter) voters;

    //Users' hashcodes - should be unique
    mapping(bytes32 => bool) hashcodes;

    //How many ballots there will be in this campaign
    uint public rounds;

    //It represents the ballot that voters are voting in
    uint public currentBallot;

    //It represents the current standard message that all voters must submit
    bytes32 public currentMessage;

    //It tells if voters may enter a center
    bytes32 public stoppingAccessionToCenters;

    //Maximum center size
    uint constant public mgz = 3;

    //Info about parties, candidates etc.
    mapping(uint => bytes32) campaignIpfsInfo;

    //Center chairpersons' tor addresses
    mapping(address => mapping(uint => bytes32)) tors;

    //Center + voter mapping
    mapping(uint => mapping(uint => address)) centerVoters;

    //Ballot + candidate mapping
    mapping(uint => mapping(uint => Candidate)) ballotCandidates;
    uint[255] ballotCandidatesCounter;

    //For statistics
    mapping(uint => mapping(uint => mapping(uint => uint))) votesPerBallotCandidateGCategory;

    //Ballot + center mappings
    mapping(uint => mapping(uint => mapping(uint => Vote))) ballotCenterVotes;
    mapping(uint => mapping(uint => mapping(uint => bool))) ballotCenterPCommitted;
    mapping(uint => mapping(uint => mapping(uint => bool))) ballotCenterPCommittedStatistics;

    //Functions

    //Create a new campaign which can have several ballots within
    constructor () {
        nationalElectoralCouncil = msg.sender;
        rounds = 2;
    }

    modifier onlyNacionalElectoralCouncil {
        require(msg.sender == nationalElectoralCouncil);
        _;
    }   

    //The insertion should be done after the creation, since there will be many candidates lists
    //Different ballots may have different lists of candidates
    function addCandidateIntoBallot(uint ballot, uint position, bytes32 candidateInfo) public onlyNacionalElectoralCouncil {
        require(ballotCandidates[ballot][position].candidateInfo == bytes32(0));
        ballotCandidates[ballot][position].candidateInfo = candidateInfo;
    }

    //In order to know how many candidates there are in a ballot
    function iterateCandidatesCounter(uint ballot) public {
        ballotCandidatesCounter[ballot] += 1;
    }

    //Get the candidate's info
    function getCandidate(uint ballot, uint candidate) public view returns (bytes32 candidateInfo, uint count){
        candidateInfo = ballotCandidates[ballot][candidate].candidateInfo;
        count = ballotCandidates[ballot][candidate].votesCount;
    }

    //Insert new ballot in ballots array
    function addBallot(bytes32 id) public onlyNacionalElectoralCouncil {
        //There may only be a determined number of rounds
        require(ballots.length <= rounds);

        ballots.push(Ballot({
            id : id,
            closed : false
            }));
    }

    //Voters interaction ends
    function closeBallot(uint ballot) public onlyNacionalElectoralCouncil {
        require(ballot < rounds);
        require(!ballots[ballot].closed);
        ballots[ballot].closed = true;
    }

    //The ballot index must be smaller than the maximum limit
    function defineCurrentBallot(uint ballot) public onlyNacionalElectoralCouncil {
        require(ballot < rounds);
        require(!ballots[ballot].closed);
        currentBallot = ballot;
    }

    //Define the current standard vote message that all voters must submit
    function defineCurrentMessage(bytes32 message) public onlyNacionalElectoralCouncil {
        currentMessage = message;
    }

    //It tells if voters may enter a center
    function defineStoppingAccessionToCenters(bytes32 str) public onlyNacionalElectoralCouncil {
        stoppingAccessionToCenters = str;
    }

    //It sets the center nationalElectoralCouncil's tor address and pubkey
    function defineTor(address person, uint pos, bytes32 value) public {
        require(msg.sender == person);
        tors[person][pos] = value;
    }

    //It returns the center nationalElectoralCouncil's tor address
    function getTor(address person, uint pos) public view returns (bytes32){
        return tors[person][pos];
    }

    //Info about parties, candidates etc.
    function defineCampaignIpfsInfo(uint pos, bytes32 value) public onlyNacionalElectoralCouncil {
        campaignIpfsInfo[pos] = value;
    }

    //It returns the center nationalElectoralCouncil's tor address
    function getCampaignIpfsInfo(uint pos) public view returns (bytes32){
        return campaignIpfsInfo[pos];
    }

    //Adding a center with its nationalElectoralCouncil
    function addCenter(address cPerson, uint category) public onlyNacionalElectoralCouncil {
        require(category < centerCategories.length);
        centers.push(Center({
            cPerson : cPerson,
            category : category,
            size : 0
            }));
    }

    //It adds a new unique category
    function addCenterCategory(bytes32 category) public onlyNacionalElectoralCouncil {
        require(category != bytes32(0));

        for (uint i = 0; i < centerCategories.length; i++) {
            if (centerCategories[i] == category) {
                return;
            }
        }
        centerCategories.push(category);
    }

    //Give the voter the right to vote on this campaign.
    function giveRightToVote(address toVoter, uint prefix, bytes32 pubkey, bytes32 hashcode) public onlyNacionalElectoralCouncil {
        require(!hashcodes[hashcode]);

        voters[toVoter].pubkey = pubkey;
        voters[toVoter].prefix = prefix;
        hashcodes[hashcode] = true;
    }

    //If this voter is a troll
    function removeRightToVote(address toVoter) public onlyNacionalElectoralCouncil onlyNacionalElectoralCouncil {
        voters[toVoter].prefix = 0;
    }

    //Add the voter to a center so that he/she can vote
    function addVoterToCenter(address voter, uint grp, uint position) public onlyNacionalElectoralCouncil {
        require(!voters[voter].hasCenter);
        require(centers[grp].size < mgz);
        require(position < mgz);
        require(centerVoters[grp][position] == address(0));
        //The nationalElectoralCouncil should give the right to vote to this voter first
        require(voters[voter].prefix > 0);

        //Making the voter part of a center
        voters[voter].center = grp;
        voters[voter].hasCenter = true;
        centers[grp].size += 1;
        centerVoters[grp][position] = voter;
    }

    //Check if a hashcode was inserted
    function checkHashcode(bytes32 hashcode) public view returns (bool){
        return hashcodes[hashcode];
    }

    //Get voter's info
    function getVoter(address voter) public view returns (bytes32 pubkey, uint prefix, uint center, bool hasCenter){
        pubkey = voters[voter].pubkey;
        prefix = voters[voter].prefix;
        center = voters[voter].center;
        hasCenter = voters[voter].hasCenter;
    }

    //It returns the addresses of the members of a center
    function getCenterVoters(uint center) public view returns (address[mgz] memory){
        address[mgz] memory addresses;
        for (uint i = 0; i < mgz; i++) {
            addresses[i] = centerVoters[center][i];
        }
        return addresses;
    }

    //It returns the pubkeys of the members of a center
    function getCenterPubkeys(uint center) public view returns (uint[mgz] memory, bytes32[mgz] memory){
        bytes32[mgz] memory pubkeys;
        uint[mgz] memory prefixes;

        for (uint i = 0; i < mgz; i++) {
            pubkeys[i] = voters[centerVoters[center][i]].pubkey;
            prefixes[i] = voters[centerVoters[center][i]].prefix;
        }
        return (prefixes, pubkeys);
    }

    //The center nationalElectoralCouncil sends the votes
    function vote(uint ballot, uint grp, uint position, bytes32 first_number, uint the_candidate) public {
        require(msg.sender == centers[grp].cPerson);
        require(!ballots[ballot].closed);
        require(ballot < rounds);
        require(position < mgz);
        require(ballotCenterVotes[ballot][grp][position].voteHash == bytes32(0));

        //Verify if this voteHash(hash) has already been entered in the array
        for (uint i = 0; i < mgz; i++) {
            if (ballotCenterVotes[ballot][grp][i].voteHash == first_number) {
                return;
            }
        }

        ballotCenterVotes[ballot][grp][position].voteHash = first_number;
        ballotCenterVotes[ballot][grp][position].candidate = the_candidate;
    }

    //For the statistics
    function getVotesPerBallotCandidateCategory(uint ballot, uint candidate, uint category) public view returns (uint){
        return votesPerBallotCandidateGCategory[ballot][candidate][category];
    }

    //It returns all sent votes regarding a ballot and a center
    function getVotes(uint ballot, uint grp) public view returns (bytes32[mgz] memory, uint[mgz] memory){
        bytes32[mgz] memory numbers;
        uint[mgz] memory candidates;
        for (uint i = 0; i < mgz; i++) {
            numbers[i] = ballotCenterVotes[ballot][grp][i].voteHash;
            candidates[i] = ballotCenterVotes[ballot][grp][i].candidate;
        }
        return (numbers, candidates);
    }

    //Check if the the votes were committed (for that ballot, center and position)
    function committed(uint ballot, uint grp, uint position) public view returns (bool){
        return ballotCenterPCommitted[ballot][grp][position];
    }

    //Check if the statistics were committed (for that ballot, center and position)
    function committedStatistics(uint ballot, uint grp, uint position) public view returns (bool){
        return ballotCenterPCommittedStatistics[ballot][grp][position];
    }

    //Committing the results and casting the votes
    function commitVotationPerPosition(uint ballot, uint grp, uint position) public {
        require(ballots[ballot].closed);
        //The ballot must be closed
        require(centers[grp].cPerson == msg.sender);
        //The votes must not have been committed before
        require(!ballotCenterPCommitted[ballot][grp][position]);

        if (ballotCenterVotes[ballot][grp][position].voteHash != bytes32(0)) {
            //Get the chosen candidate
            uint candidate = ballotCenterVotes[ballot][grp][position].candidate;
            //Add this vote
            ballotCandidates[ballot][candidate].votesCount += 1;
            ballotCenterPCommitted[ballot][grp][position] = true;
        }
    }

    //Committing the statistics
    function commitVotationStatisticsPerPosition(uint ballot, uint grp, uint position) public {
        require(ballots[ballot].closed);
        //The ballot must be closed
        require(centers[grp].cPerson == msg.sender);
        //The votes must not have been committed before
        require(!ballotCenterPCommittedStatistics[ballot][grp][position]);

        if (ballotCenterVotes[ballot][grp][position].voteHash != bytes32(0)) {
            //Get the chosen candidate
            uint candidate = ballotCenterVotes[ballot][grp][position].candidate;
            //Statistics
            uint category = centers[grp].category;
            votesPerBallotCandidateGCategory[ballot][candidate][category] += 1;
            ballotCenterPCommittedStatistics[ballot][grp][position] = true;
        }
    }

    //centers.length
    function howManyCenters() public view returns (uint){
        return centers.length;
    }

    //ballots.length
    function howManyBallots() public view returns (uint){
        return ballots.length;
    }

    //centerCategories.length
    function howManyCenterCategories() public view returns (uint){
        return centerCategories.length;
    }

    //Candidates length
    function howManyCandidatesInBallot(uint ballot) public view returns (uint){
        return ballotCandidatesCounter[ballot];
    }
}