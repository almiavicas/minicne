from brownie import ElectionV2
from brownie.network.account import LocalAccount

def main(acct: LocalAccount):
    return acct.deploy(ElectionV2)
