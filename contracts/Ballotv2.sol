pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./SafeMath.sol";

contract ElectionV2 {
    using SafeMath for uint;

    struct Voter {
        address id;
        uint centerId;
        uint locationId;
    }
    struct Center {
        uint id;
        uint locationId;
    }
    struct Location {
        uint id;
        string name;
        uint voters;
    }
    struct Candidate {
        address id;
        uint ballotId;
        uint roundId;
        uint votesCount;
    }
    struct Ballot {
        uint id;
        bool closed;
        bool global;
        uint locationId;
        uint round;
    }
    
    address public cne;
    uint maxrounds;
    Location[] public locations;
    Center[] public centers;
    Voter[] public voters;
    Candidate[] public candidates;
    Ballot[] public ballots;
    mapping(uint => mapping(uint => Center)) centersByLocation;
    mapping(uint => mapping(address => Voter)) votersByCenter;


    constructor() {
        cne = msg.sender;
        maxrounds = 2;
    }

    modifier CNEOnly {
        require(msg.sender == cne);
        _;
    }

    /**
        @notice Find a location by id.
        @param id - Location id.
        @return index if exists. Else, Throw a revert exception.
     */
    function findLocationIndex(uint id) public view returns (uint) {
        for (uint i = 0; i < locations.length; i++) {
            if (locations[i].id == id) {
                return i;
            }
        }
        revert('Could not find the requested location');
    }

    /**
        @notice Find a center by id in a specific location.
        @param id - Center id.
        @return index if exists. Else, throw a revert exception.
     */
    function findCenterIndex(uint id) public view returns (uint) {
        for (uint i = 0; i < centers.length; i++) {
            if (centers[i].id == id) {
                return i;
            }
        }
        revert('Could not find the requested center');
    }

    /**
        @notice Find a voter by address.
        @param id - Voter address.
        @return index if exists. Else, throw a revert exception.
     */
    function findVoterIndex(address id) public view returns (uint) {
        for (uint i = 0; i < voters.length; i++) {
            if (voters[i].id == id) {
                return i;
            }
        }
        revert('Could not find the requested voter');
    }

    /**
        @notice Find a ballot by id.
        @param id - Ballot id.
        @return index if exists. Else, throw a revert exception.
     */
    function findBallotIndex(uint id) public view returns (uint) {
        for (uint i = 0; i < ballots.length; i++) {
            if (ballots[i].id == id) {
                return i;
            }
        }
        revert('Could not find the requested ballot');
    }

    /**
        @notice Find a candidate by address.
        @param id - Candidate address.
        @return index if exists. Else, throw a revert exception.
     */
    function findCandidateIndex(address id) public view returns (uint) {
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].id == id) {
                return i;
            }
        }
        revert('Could not find the requested candidate');
    }

    /**
        @notice Get Locations.
        @return locations array.
     */
    function getLocations() public view returns (Location[] memory) {
        return locations;
    }

    /**
        @notice Get centers.
        @return centers array.
     */
    function getCenters() public view returns (Center[] memory) {
        return centers;
    }

    /**
        @notice Get voters.
        @return voters array.
     */
    function getVoters() public view returns (Voter[] memory) {
        return voters;
    }

    /**
        @notice Add a new location to the Contract.
        @param id - The location id.
        @param name - The location name.
        @return Wether the location was created or not.
     */
    function addLocation(uint id, string memory name) public CNEOnly returns (bool) {
        for (uint i = 0; i < locations.length; i++) {
            require(locations[i].id != id);
        }
        locations.push(Location(id, name, 0));
        return true;
    }

    /**
        @notice Add a new center to the Contract.
        @param id - The center id.
        @param locationId - The location where the center should be created.
        @return Wether the center was successfully created or not.
     */
    function addCenter(uint id, uint locationId) public CNEOnly returns (bool) {
        for (uint i = 0; i < centers.length; i++) {
            require(centers[i].id != id);
        }
        Center memory c = Center(id, locationId);
        centers.push(c);
        centersByLocation[locationId][id] = c;
        return true;
    }

    /** 
        @notice Add a new voter to the Contract.
        @param id - The voter identifier.
        @param centerId - The center identifier where the voter should be added.
        @param locationId - The location identifier where the center belongs to.
        @return Wether the voter was successfully created or not.
     */
    function addVoter(address id, uint centerId, uint locationId) public CNEOnly returns (bool) {
        for (uint i = 0; i < voters.length; i++) {
            require(voters[i].id != id);
        }
        uint index = findLocationIndex(locationId);
        Location memory l = locations[index];
        l.voters = l.voters.add(1);
        Voter memory v = Voter(id, centerId, locationId);
        voters.push(v);
        votersByCenter[centerId][id] = v;
        return true;
    }

    /**
        @notice Add a Governor Ballot. Governor ballots are ballots by locations.
        @param id - Ballot id.
        @param locationId - Location for the ballot.
        @return Wether the Governor Ballot was successfully created or not.
     */
    function addGovernorBallot(uint id, uint locationId) public CNEOnly returns (bool) {
        for (uint i = 0; i < ballots.length; i++) {
            require(ballots[i].id != id);
        }
        uint index = findLocationIndex(locationId);
        Location memory l = locations[index];
        Ballot memory b = Ballot(id, true, false, l.id, 0);
        ballots.push(b);
        return true;
    }

    /**
        @notice Add a President Ballot. President Ballots are global ballots.
        @param id - Ballot id.
        @return Wether the governor ballot was successfully created or not.
     */
    function addPresidentBallot(uint id) public CNEOnly returns (bool) {
        for (uint i = 0; i < ballots.length; i++) {
            require(ballots[i].id != id);
        }
        Ballot memory b = Ballot(id, true, true, 0, 0);
        ballots.push(b);
        return true;
    }

    /**
        @notice Add candidate to a ballot next round.
        @param ballotId - The existing ballot id.
        @param voterId - The existing voter id.
        @return Wether the candidate was successfully added or not.
     */
    function addCandidateToBallot(uint ballotId, address voterId) public CNEOnly returns (bool) {
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].id == voterId) {
                require(ballots[candidates[i].ballotId].id != ballotId);
            }
        }
        uint ballotIndex = findBallotIndex(ballotId);
        Ballot memory b = ballots[ballotIndex];
        require(b.round == 0);
        uint voterIndex = findVoterIndex(voterId);
        Voter memory v = voters[voterIndex];
        if (!b.global) {
            require(b.locationId == v.locationId);
        }
        Candidate memory c = Candidate(voterId, b.id, 1, 0);
        candidates.push(c);
        return true;
    }

    function openBallot(uint id) public CNEOnly returns (bool) {
        uint index = findBallotIndex(id);
        Ballot memory b = ballots[index];
        uint ballotCandidates = 0;
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].ballotId == b.id) {
                ballotCandidates = ballotCandidates.add(1);
            }
        }
        require(ballotCandidates > 1, 'Ballot requires at least 2 candidates to open');
        require(b.closed, 'Ballot requires to be closed');
        require(b.round < maxrounds, 'Ballot rounds requires to be less than maxrounds');
        b.closed = false;
        b.round = b.round.add(1);
        ballots[index] = b;
        return true;
    }

    function closeBallot(uint id) public CNEOnly returns (bool) {
        uint index = findBallotIndex(id);
        Ballot memory b = ballots[index];
        require(!b.closed);
        require(b.round == 2, 'Ballot must have two rounds to close');
        b.closed = true;
        ballots[index] = b;
        return true;
    }

    function nextRound(uint ballotId) public CNEOnly returns (bool) {
        uint index = findBallotIndex(ballotId);
        Ballot memory b = ballots[index];
        require(b.round < maxrounds);
        require(candidates.length > 1);
        require(!b.closed);
        b.closed = true;
        Candidate memory c1 = Candidate(address(0x00), b.id, 1, 0);
        Candidate memory c2 = Candidate(address(0x00), b.id, 1, 0);
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].ballotId == b.id) {
                if (candidates[i].votesCount >= c1.votesCount) {
                    c2 = c1;
                    c1 = candidates[i];
                } else if (candidates[i].votesCount >= c2.votesCount) {
                    c2 = candidates[i];
                }
            }
        }
        c1.roundId = 2;
        c1.votesCount = 0;
        c2.roundId = 2;
        c2.votesCount = 0;
        candidates.push(c1);
        candidates.push(c2);
        return openBallot(ballotId);
    }
}