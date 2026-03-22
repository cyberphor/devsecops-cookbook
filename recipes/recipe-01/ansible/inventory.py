"""Module for updating Ansible host inventory files"""
from argparse import ArgumentParser
from os.path import isfile
from yaml import safe_load, dump

def update(file_path: str, host_group: list, host: str):
    """Adds host group and/or host to inventory if they do not exist"""
    if isfile(file_path):
        with open(file_path, "r", encoding = "UTF-8") as file_stream:
            inventory = safe_load(file_stream)
    else:
        inventory = {host_group: {"hosts": {}}}

    if host_group not in inventory.keys():
        inventory[host_group] = {"hosts": {}}
    
    hosts = inventory[host_group]["hosts"]
    if host not in hosts:
        inventory[host_group]["hosts"][host] = None
        with open(file_path, "w", encoding = "UTF-8") as file_stream:
            new_inventory = dump(inventory, default_flow_style = False).replace("null","")
            file_stream.write(new_inventory)

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("--file-path", required = True)
    parser.add_argument("--host-group", required = True)
    parser.add_argument("--host", required = True)
    args = parser.parse_args()
    update(args.file_path, args.host_group, args.host)