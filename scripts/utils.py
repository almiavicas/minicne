from typing import Dict, List

def parse_locations_file(filename: str) -> List[Dict[str, Dict[str, int]]]:
    locations = []
    with open(filename, encoding="utf-8") as _file:
        lines = _file.readlines()
    for line in lines:
        args = line.split()
        locations.append({args[0]: {
            'voters': int(args[1]),
            'centers': int(args[2]),
        }})
    return locations
