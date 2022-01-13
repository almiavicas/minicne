from enum import Enum
from multiprocessing import set_start_method, Process
from logging import FileHandler, basicConfig, INFO, getLogger, Formatter
from socket import socket, SOCK_DGRAM, AF_INET
from json import loads, dumps
from typing import List
from brownie import accounts, network
from brownie.network.account import Account

LOCALHOST = '127.0.0.1'
BUFSIZE = 2**14 - 1
Event = Enum(
    'Event',
    (
        'VOTE',
    )
)

class Master:
    'Master class for a votes center.'
    LOG_FORMAT = "%(asctime)s | %(name)s: %(levelname)s - %(message)s"
    def __init__(self, name: str, port: int, log_file: str):
        self.name = name
        self.port = port
        network.main.connect('development')
        self.contract = ElectionV2[0]
        set_start_method('spawn')
        basicConfig(level=INFO, format=self.LOG_FORMAT)
        self.log = getLogger(name)
        formatter = Formatter(fmt=self.LOG_FORMAT)
        filehandler = FileHandler(log_file, mode='w')
        filehandler.setFormatter(formatter)
        self.log.addHandler(filehandler)

    def listen(self):
        sock = socket(AF_INET, SOCK_DGRAM)
        sock.bind((LOCALHOST, self.port))
        self.log.info('Listening on port %d', self.port)
        while True:
            message, addr = sock.recvfrom(BUFSIZE)
            self.handle_message(message, addr, sock)

    def handle_message(self, message: bytes, address: tuple, sock: socket):
        decoded_message = loads(message.decode())
        event = decoded_message['event']
        data = decoded_message['data']
        if event == Event.VOTE.value:
            self.log.info('%s received from %s', Event.VOTE, address)
            self.event_vote(data, address, sock)

    def event_vote(self, data: dict, address: tuple, sock: socket):
        try:    
            acct = accounts.at(data['account'])
            ballot_id = data['ballot_id']
            round_id = data['round_id']
            candidate = accounts.at(data['candidate'])
            self.create_sender(acct, ballot_id, round_id, candidate)
            result = {
                'success': 'Vote delivered to sender to commit to blockchain.'
            }
        except ValueError as e:
            result = {
                'error': str(e)
            }
        finally:
            response = {'result': result}
            sock.sendto(dumps(response).encode(), address)

    def create_sender(self, acct: Account, ballotId: int, roundId: int, candidateId: Account):
        self.log.info('Creating new vote sender')
        sender = Process(target=self.send_vote, args=[self, acct, ballotId, roundId, candidateId])
        sender.start()
    
    def send_vote(self, acct: Account, ballotId: int, roundId: int, candidateId: Account):
        self.contract.vote(ballotId, roundId, candidateId, {'from': acct})
        self.log.info(
            'Vote sent. account: %s, ballotId: %d, roundId: %d, candidate: %s',
            acct, ballotId, roundId, candidateId,
        )

def main(
        name: str = __name__,
        port: int = 3000,
        log_file: str = __name__,
        contracts: List[str] = ['contracts/BallotV2.sol']
    ):
    server = Master(name, port, log_file)
    server.listen()
    