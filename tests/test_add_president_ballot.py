import pytest
from brownie import ElectionV2, accounts

@pytest.fixture
def election():
    return accounts[0].deploy(ElectionV2)

def test_add_governor_ballot(election):
    assert election.addPresidentBallot(0, {'from': accounts[0]})
    try:
        election.addPresidentBallot(1, {'from': accounts[1]})
        assert False
    except AttributeError:
        pass