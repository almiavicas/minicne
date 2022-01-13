'''Generador de votos.
'''
from random import randrange, choice, sample
import pandas as pd
from brownie.network.contract import ProjectContract
from brownie.network.account import LocalAccount


def main(
    contract: ProjectContract,
    acct: LocalAccount,
    min_abstention: float = 0.1,
    max_abstention: float = 0.3,
):
    locations = contract.getLocations({'from': acct})
    locations = [tuple(loc) for loc in locations]
    locations_df = pd.DataFrame(locations, columns=['id', 'name', 'voters'])
    voters = contract.getVoters({'from': acct})
    voters = [tuple(voter) for voter in voters]
    voters_df = pd.DataFrame(voters, columns=['address', 'centerId', 'locationId'])
    candidates = contract.getCandidates({'from': acct})
    candidates = [tuple(c) for c in candidates]
    candidates_df = pd.DataFrame(candidates, columns=['id', 'ballotId', 'roundId', 'votesCount'])
    ballots = contract.getBallots({'from': acct})
    ballots = [tuple(b) for b in ballots]
    ballots_df = pd.DataFrame(ballots, columns=['id', 'closed', 'global', 'locationId', 'round'])
    print('Generating Governors votes')
    location_ids = list(locations_df.id)
    for loc_id in location_ids:
        location = locations_df[locations_df.id == loc_id]
        registered_voters = int(location.voters)
        abstention = registered_voters * randrange(min_abstention * 100, max_abstention * 100) // 100
        votes_to_generate = registered_voters - abstention
        location_voters = voters_df[voters_df.locationId == loc_id]
        print(location_voters)
        governor_ballot = ballots_df[ballots_df.locationId == loc_id]
        governor_ballot = governor_ballot[~governor_ballot['global']]
        print(governor_ballot)
        ballot_candidates = candidates_df[candidates_df.ballotId == list(governor_ballot.id)[0]]
        voters_to_vote = sample(list(location_voters.address), votes_to_generate)
        print('Location: %s. Voters: %d. Abstention: %d' %(list(location.name)[0], registered_voters, abstention))
        for address in voters_to_vote:
            candidate = choice(list(ballot_candidates.id))
            contract.vote(list(governor_ballot.id)[0], list(governor_ballot['round'])[0], candidate, {'from': address})
    print('Generating Presidents votes')
    registered_voters = len(voters_df)
    abstention = registered_voters * randrange(min_abstention * 100, max_abstention * 100) // 100
    votes_to_generate = registered_voters - abstention
    print('Voters: %d. Abstention: %d' %(registered_voters, abstention))
    president_ballot = ballots_df[ballots_df['global']]
    ballot_candidates = candidates_df[candidates_df.ballotId == list(president_ballot.id)[0]]
    voters_to_vote = sample(list(voters_df.address), votes_to_generate)
    for address in voters_to_vote:
        candidate = choice(list(ballot_candidates.id))
        contract.vote(list(president_ballot.id)[0], list(president_ballot['round'])[0], candidate, {'from': address})

