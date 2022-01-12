import pytest
from brownie import ElectionV2, accounts

@pytest.fixture
def election():
    return accounts[0].deploy(ElectionV2)

def test_next_round(election):
    election.addLocation(0, 'Zulia', {'from': accounts[0]})
    election.addCenter(0, 0, {'from': accounts[0]})
    election.addGovernorBallot(0, 0, {'from': accounts[0]})
    election.addVoter(accounts[0], 0, 0, {'from': accounts[0]})
    election.addVoter(accounts[1], 0, 0, {'from': accounts[0]})
    election.addCandidate(0, accounts[0], {'from': accounts[0]})
    election.addCandidate(0, accounts[1], {'from': accounts[0]})
    election.openBallot(0, {'from': accounts[0]})
    election.vote(0, 1, accounts[0], {'from': accounts[0]})
    assert election.nextRound(0, {'from': accounts[0]})
    candidates = election.getCandidates()
    for candidate in candidates:
        _, ballotId, roundId, votesCount = candidate
        assert ballotId == 0
        assert roundId == 2
        assert votesCount == 0
