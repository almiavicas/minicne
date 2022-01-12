import pytest
from brownie import ElectionV2, accounts

@pytest.fixture
def election():
    return accounts[0].deploy(ElectionV2)

def test_add_candidate_to_governor_ballot(election):
    election.addLocation(0, 'Zulia', {'from': accounts[0]})
    election.addCenter(0, 0, {'from': accounts[0]})
    election.addGovernorBallot(0, 0, {'from': accounts[0]})
    election.addVoter(accounts[0], 0, 0, {'from': accounts[0]})
    assert election.addCandidate(0, accounts[0], {'from': accounts[0]})

def test_add_candidate_to_president_ballot(election):
    election.addLocation(0, 'Zulia', {'from': accounts[0]})
    election.addCenter(0, 0, {'from': accounts[0]})
    election.addPresidentBallot(0, {'from': accounts[0]})
    election.addVoter(accounts[0], 0, 0, {'from': accounts[0]})
    assert election.addCandidate(0, accounts[0], {'from': accounts[0]})
