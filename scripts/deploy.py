from brownie import ElectionV2, accounts

def main(account_id: str = 'deployment_account'):
    acct = accounts.load(account_id)
    return acct.deploy(ElectionV2)
