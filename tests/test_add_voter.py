import pytest
from brownie import ElectionV2, accounts

@pytest.fixture
def election():
    return accounts[0].deploy(ElectionV2)

def test_add_voter(election):
    election.addLocation(0, 'Zulia', {'from': accounts[0]})
    voters = election.getVoters()
    assert len(voters) == 0
    assert election.addVoter(accounts[0], 0, 0, {'from': accounts[0]})
    voters = election.getVoters()
    assert len(voters) == 1
    try:
        election.addVoter(accounts[1], 0, 0, {'from': accounts[1]})
        assert False
    except AttributeError:
        voters = election.getVoters()
        assert len(voters) == 1
