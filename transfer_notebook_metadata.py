"""
Transfer notebook nikola metadata and cell tags from one notebook to another
"""
import json
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('from_path')
parser.add_argument('to_path')
args = parser.parse_args()

with open(args.from_path, 'r') as f:
    from_json = json.load(f)
with open(args.to_path, 'r') as f:
    to_json = json.load(f)

# Transfer metadata for nikola
to_json['metadata']['nikola'] = from_json['metadata']['nikola']

# Go through each to cell, find a from cell with the same id and
# transfer the tags
for to_cell in to_json['cells']:
    to_cell_id = to_cell['metadata']['id']
    for from_cell in from_json['cells']:
        if from_cell['metadata']['id'] != to_cell_id:
            continue
        if 'tags' in from_cell['metadata']:
            to_cell['metadata']['tags'] = from_cell['metadata']['tags']
            print('transfered tags')

with open(args.to_path, 'w') as f:
    json.dump(to_json, f)
