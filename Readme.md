# MiniCNE

MiniCNE is a University Project for developing a contract that mocks Ballots and their entire structure.

# Prerequesites

Before deploying your contract, you need to add an account managed by brownie. If you want a fresh new account, run the following command.

```bash
brownie accounts generate deployment_account
```

# Usage

To start interacting with the contract, run `brownie console`.

You can modifiy the `deployment_account` part as it is the identifier of the account. However, the specified id will be the default for further scripts.

To use the smart contract in a local development blockchain, run the following command.

```python
contract = run('scripts/deploy.py')
```

This will deploy your smart contract and store a reference to it in the contract variable.

### Generating voters, locations and centers

To generate voters, locations and centers you need the previous step to have an interactive console. After deploying your contract, run the following command inside the console:

```python
run('scripts/genVotante.py', args=['localidades.txt', contract])
```
