import pytest
from brownie import ElectionV2, accounts

@pytest.fixture
def election():
    return accounts[0].deploy(ElectionV2)

def test_add_governor_ballot(election):
    election.addLocation(0, 'Zulia', {'from': accounts[0]})
    assert election.addGovernorBallot(0, 0, {'from': accounts[0]})
    try:
        election.addGovernorBallot(1, 0, {'from': accounts[1]})
        assert False
    except AttributeError:
        pass