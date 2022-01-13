'''Generador de Votantes.
El generador de votantes define un conjunto de localidades electorales y asigna a cada
votante un centro de votacion en su localidad de forma aleatoria. Ademas, de entre los
votantes creados selecciona un subconjunto razonable de estos (1%) como candidatos a los
diferentes cargos a ser elegidos.

Archivo de localidades.
Sintaxis:

Local1 numVotantes1 numeroCentrosVotacion1
Local2 numVotantes2 numeroCentrosVotacion2
...
Localn numVotantesn numeroCentrosVotacionn

donde:
    - Locali: Representa el nombre de la localidad
    - numVotantesi: Numero de votantes inscritos para esa localidad
    - numeroCentrosVotacioni: Numero de centros de votacion disponibles en esa localidad.
'''
from random import choice
from brownie import accounts
from brownie.network.contract import ProjectContract
from brownie.network.account import LocalAccount
from scripts.utils import parse_locations_file


def main(filename: str, contract: ProjectContract, acct: LocalAccount):
    locations = parse_locations_file(filename)
    it = iter(accounts)
    centers_created = 0
    for i, location in enumerate(locations):
        name = list(location.keys())[0]
        voters = location[name]['voters']
        centers = location[name]['centers']
        contract.addLocation(i, name, {'from': acct})
        for x in range(centers_created, centers_created + centers):
            contract.addCenter(x, i, {'from': acct})
        for x in range(voters):
            try:
                voter = next(it)
            except StopIteration:
                voter = accounts.add()
            finally:
                contract.addVoter(voter, choice(range(centers_created, centers_created + centers)), i, {'from': acct})
        centers_created += centers
