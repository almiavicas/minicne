# MiniCNE

MiniCNE is a University Project for developing a contract that mocks Ballots and their entire structure.

# Prerequesites

Before deploying your contract, you need to add an account managed by brownie. If you want a fresh new account, run the following command.

```bash
brownie accounts generate deployment_account
```

# Usage

The following commands make an entire electoral process from start to finish. In order to execute these commands you must enter in a brownie console by typing the command `brownie console`.

```python
acct = accounts.load('deployment_account')
contract = run('scripts/deploy.py', args=[acct])
run('scripts/genVotante.py', args=['localidades.txt', contract, acct])
run('scripts/genVotaciones.py', args=[contract, acct])
run('scripts/genVotos.py', args=[contract, acct])
for i in range(5):
    tx = contract.viewBallotInfo(i)
    print(tx.events)
    contract.nextRound(i, {'from': acct})

run('scripts/genVotos.py', args=[contract, acct, 0.05, 0.35])
for i in range(5):
    contract.closeBallot(i, {'from': acct})
    tx = contract.viewBallotInfo(i)
    print(tx.events)

```

## Step by step explanation

### Fetch deployment account

We created a deployment account in the [prerequesites](#prerequesites) step. We need to fetch that account and enter the passphrase. This is the account we will be using as the contract owner.

```python
acct = accounts.load('deployment_account')
```

### Deploy contract

```python
contract = run('scripts/deploy.py', args=[acct])
```

The previous commmands simply deploys the contract to the networks we are currently connected to. By default, brownie connects to a local development network with a node hosted by ganache.

### Create locations, centers and voters

Now we enter to some specific datastructures for our contract.

- Locations: They represent entities where electoral processes for governors can be made. A governor is elected for a specific Location. Also, centers belong to a specific location and voters belong to a specific center and location.

- Centers: They represent an space where the voter can make a vote. These centers are necessary linked to a location and can have multiple voters.

- Voters: Represented by addresses, they hold the power to vote. They are related to a specific center and location. No voter is able to participate in a vote of a location different than his, unless the election is a presidential election.

These three entities can be only generated by the contract owner. To generate these structures, run the following command:

```python
run('scripts/genVotante.py', args=['localidades.txt', contract, acct])
```

### Create ballots (Electoral processes)

So once we have locations, centers and voters, we have everything to start an electoral process. There are two types of ballots:

- Governor Ballot: They represent an electoral process for a specific location, where only voters from that location can vote and only voters from the specific location can be candidates.

- President Ballot: They represent a global electoral process. Everyone can vote and anyone can be a candidate.

The following command generates a ballot for each location and a presidential ballot. It also selects a 1% of the voters for each ballot to be candidates (minimum 2 candidates will be selected), and opens the electoral processes for voting:

```python
run('scripts/genVotaciones.py', args=[contract, acct])
```

### Voting process

Now that ballots are open, voters can submit their votes. The following script generates votes for each ballot with a random abstention percentage. The default abstention percentage range is from 10% to 30%, but it can easily be modified:

```python
run('scripts/genVotos.py', args=[contract, acct])
```

### Ballots Summary

Now that people have voted, we can see the current results for a ballot. The following command will print on your screen the results of a specific ballot:

```python
tx = contract.viewBallotInfo(0)
print(tx.events)
```

Lets study an example output:

```python
{'ViewBallotResultsByLocation': [OrderedDict([('round', 1), ('candidateAddress', '0x00eb3Ab11f470FBFCc58116382D7cd4242C57E7a'), ('votesCount', 9), ('location', 'Amazonas'), ('percentage', 56)]), OrderedDict([('round', 1), ('candidateAddress', '0x6a3668D2430DA575989198DEdEE9382f31917d0D'), ('votesCount', 7), ('location', 'Amazonas'), ('percentage', 43)])], 'WinnerResult': [OrderedDict([('round', 1), ('candidateAddress', '0x00eb3Ab11f470FBFCc58116382D7cd4242C57E7a'), ('votesCount', 9), ('percentage', 56), ('totalVotes', 16), ('abstention', 12)])]}
```

Prettifying this output we get the following:

```python
{
    'ViewBallotResultsByLocation': [
        OrderedDict(
            [
                ('round', 1),
                ('candidateAddress', '0x00eb3Ab11f470FBFCc58116382D7cd4242C57E7a'),
                ('votesCount', 9),
                ('location', 'Amazonas'),
                ('percentage', 56)
            ]
        ),
        OrderedDict(
            [
                ('round', 1),
                ('candidateAddress', '0x6a3668D2430DA575989198DEdEE9382f31917d0D'),
                ('votesCount', 7),
                ('location', 'Amazonas'),
                ('percentage', 43)
            ]
        )
    ],
    'WinnerResult': [
        OrderedDict(
            [
                ('round', 1),
                ('candidateAddress', '0x00eb3Ab11f470FBFCc58116382D7cd4242C57E7a'),
                ('votesCount', 9),
                ('percentage', 56),
                ('totalVotes', 16),
                ('abstention', 12)
            ]
        )
    ]
}
```

The electoral process consists on elections for governors and president. Each governor election is handled separately from one another. Same happens with a presidential election.

The main difference between governors and presidential elections is that the voters for governors elections are limited to the voters registered in the specific location (For example, for `Zulia` state, only voters registered in `Zulia` location should be able to vote). In a presidential election, all voters are allowed to vote.
