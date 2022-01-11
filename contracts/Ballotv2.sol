pragma solidity ^0.8.0;

contract Election {
    struct Voter {
        address id;
        uint centerId;
        uint locationId;
    }
    struct Center {
        uint id;
        uint locationId;
        Voter[] voters;
    }
    struct Location {
        uint id;
        string name;
        Center[] centers;
        uint voters;
    }
    
    address public cne;
    Location[] public locations;

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
        @param location - Location struct.
        @param id - Center id.
        @return Center if found. Else, throw a revert exception.
     */
    function findCenter(Location memory location, uint id) public view returns (Center memory) {
        for (uint i = 0; i < location.centers.length; i++) {
            if (location.centers[i].id == id) {
                return location.centers[i];
            }
        }
        revert('Could not find the requested center');
    }

    modifier CNEOnly {
        require(msg.sender == cne);
        _;
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
        locations.push(Location(id, name, new Center[](0), 0));
        return true;
    }

    /**
        @notice Add a new center to the Contract.
        @param id - The center id.
        @param locationId - The location where the center should be created.
        @return Wether the center was successfully created or not.
     */
    function addCenter(uint id, uint locationId) public CNEOnly returns (bool) {
        Location memory location = findLocation(locationId);
        for (uint i = 0; i < location.centers.length; i++) {
            require(location.centers[i].id != id);
        }
        location.centers.push(Center(id, location.id, new Voter[](0)));
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
        Location memory location = findLocation(locationId);
        Center memory center = findCenter(location, centerId);
        for (uint i = 0; i < center.voters.length; i++) {
            require(center.voters[i].id != id);
        }
        center.voters.push(new Voter(id, centerId, locationId));
        return true;
    }
}