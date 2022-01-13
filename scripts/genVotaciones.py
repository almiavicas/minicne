from random import choices
from math import ceil
import pandas as pd
from brownie import accounts
from brownie.network.contract import ProjectContract
from brownie.network.account import LocalAccount

def main(contract: ProjectContract, acct: LocalAccount):
    locations = contract.getLocations({'from': acct})
    locations = [tuple(loc) for loc in locations]
    locations_df = pd.DataFrame(locations, columns=['id', 'name', 'voters'])
    voters = contract.getVoters({'from': acct})
    voters = [tuple(voter) for voter in voters]
    voters_df = pd.DataFrame(voters, columns=['address', 'centerId', 'locationId'])
    location_ids = list(locations_df.id)
    for i, loc_id in enumerate(location_ids):
        contract.addGovernorBallot(i, loc_id, {'from': acct})
        voters = list(voters_df[voters_df.locationId == loc_id].address)
        voters_to_candidates = choices(voters, k=max(ceil(len(voters) / 100), 2))
        for voter in voters_to_candidates:
            contract.addCandidate(i, voter, {'from': acct})
        contract.openBallot(i, {'from': acct})
    contract.addPresidentBallot(len(location_ids), {'from': acct})
    voters = list(voters_df.address)
    voters_to_candidates = choices(voters, k=max(ceil(len(voters) / 100), 2))
    for voter in voters_to_candidates:
        contract.addCandidate(len(location_ids), voter, {'from': acct})
    contract.openBallot(len(location_ids), {'from': acct})
