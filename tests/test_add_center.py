import pytest
from brownie import ElectionV2, accounts

@pytest.fixture
def election():
    return accounts[0].deploy(ElectionV2)

def test_add_center(election):
    centers = election.getCenters()
    assert len(centers) == 0
    assert election.addCenter(0, 0, {'from': accounts[0]})
    centers = election.getCenters()
    assert len(centers) == 1
    try:
        election.addCenter(1, 0, {'from': accounts[1]})
        assert False
    except AttributeError:
        centers = election.getCenters()
        assert len(centers) == 1
