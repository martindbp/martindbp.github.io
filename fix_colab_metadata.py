import json
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('colab_notebook_path')
parser.add_argument('fix_path')
args = parser.parse_args()

with open(args.colab_notebook_path, 'r') as f:
    colab_notebook_json = json.load(f)
with open(args.fix_path, 'r') as f:
    fix_json = json.load(f)

print(colab_notebook_json)
print(fix_json)
