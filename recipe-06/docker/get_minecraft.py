"""Module for downloading the latest version of Minecraft"""
from requests import session
import argparse
import json

def get_latest_version(version_manifest_url: str):
    """Function for downloading the latest version of Minecraft"""
    with session() as browser:
        web_page = browser.get(version_manifest_url)
        version_manifest = json.loads(web_page.text)
        for version in version_manifest['versions']:
            if version['id'] == version_manifest['latest']['release']:
                latest_release_manifest_url = version['url']
                break
        latest_release_manifest = browser.get(latest_release_manifest_url)
        latest_release_download_url = json.loads(latest_release_manifest.text)['downloads']['server']['url']
        latest_release_download = browser.get(latest_release_download_url, allow_redirects = True)
    with open('minecraft.jar', 'wb') as jar:
        jar.write(latest_release_download.content)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--version-manifest-url", type = str, default = "https://launchermeta.mojang.com/mc/game/version_manifest.json")
    args = parser.parse_args()
    if args.version_manifest_url:
        get_latest_version(args.version_manifest_url)
    else: 
        parser.print_help()