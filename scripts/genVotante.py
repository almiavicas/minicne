from argparse import ArgumentParser

if __name__ == '__main__':
    parser = ArgumentParser(description='''Generador de Votantes.
    El generador de votantes define un conjunto de localidades electorales y asigna a cada
    votante un centro de votacion en su localidad de forma aleatoria. Ademas, de entre los
    votantes creados selecciona un subconjunto razonable de estos (1%) como candidatos a los
    diferentes cargos a ser elegidos.''')
    parser.add_argument('localidades', help='''Archivo de localidades.
    Sintaxis:
    <Local1 numVotantes1 numeroCentrosVotacion1>
    donde:
        - Locali: Representa el nombre de la localidad
        - numVotantesi: Numero de votantes inscritos para esa localidad
        - numeroCentrosVotacioni: Numero de centros de votacion disponibles en esa localidad.
    ''')
    args = parser.parse_args()
