import pytest
from brownie import ElectionV2, accounts

@pytest.fixture
def election():
    return accounts[0].deploy(ElectionV2)

def test_add_location(election):
    locations = election.getLocations()
    assert len(locations) == 0
    assert election.addLocation(0, 'Zulia', {'from': accounts[0]})
    locations = election.getLocations()
    assert len(locations) == 1
    try:
        election.addLocation(1, 'DistritoCapital', {'from': accounts[1]})
    except AttributeError:
        locations = election.getLocations()
        assert len(locations) == 1

def test_add_center(election):
    centers = election.getCenters()
    assert len(centers) == 0
    assert election.addCenter(0, 0, {'from': accounts[0]})
    centers = election.getCenters()
    assert len(centers) == 1
    try:
        election.addCenter(1, 0, {'from': accounts[1]})
    except AttributeError:
        centers = election.getCenters()
        assert len(centers) == 1
