pragma solidity ^0.8.0;

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
    
    address public cne;
    Location[] public locations;
    Center[] public centers;
    Voter[] public voters;
    mapping(uint => mapping(uint => Center)) centersByLocation;
    mapping(uint => mapping(address => Voter)) votersByCenter;


    constructor() {
        cne = msg.sender;
    }

    modifier CNEOnly {
        require(msg.sender == cne);
        _;
    }

    /**
        @notice Find a location by id.
        @param id - Location id.
        @return Location if found. Else, Throw a revert exception.
     */
    function findLocation(uint id) public view returns (Location memory) {
        for (uint i = 0; i < locations.length; i++) {
            if (locations[i].id == id) {
                return locations[i];
            }
        }
        revert('Could not find the requested location');
    }

    /**
        @notice Find a center by id in a specific location.
        @param id - Center id.
        @return Center if found. Else, throw a revert exception.
     */
    function findCenter(uint id) public view returns (Center memory) {
        for (uint i = 0; i < centers.length; i++) {
            if (centers[i].id == id) {
                return centers[i];
            }
        }
        revert('Could not find the requested center');
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
        Location memory l = findLocation(locationId);
        l.voters = l.voters.add(1);
        Voter memory v = Voter(id, centerId, locationId);
        voters.push(v);
        votersByCenter[centerId][id] = v;
        return true;
    }
}