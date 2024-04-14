import requests
from bs4 import BeautifulSoup
import re
import json

def get_info():
    base_url = "https://cmake.org/files/"

    releases = {'darwin': [],'windows':[],"linux":[]}
    resp = requests.get(base_url)
    resp.raise_for_status()

    big_version_urls = []
    soup = BeautifulSoup(resp.content, 'html.parser')
    
    for a in soup.find_all('a', href=True):
        href = a['href']
        sn = re.match(r'^v\d', href)
        es = href.endswith('/')
        version = href[:-1]
        if sn and es :
            big_version_urls.append(base_url + version)

    pattern = r"cmake-(\d+\.\d+\.?\d*[-\w\d]*)-([\w\d]+)-([\w\d_-]+)"

    for url in big_version_urls:
        resp = requests.get(url)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.content, 'html.parser')
        
        for a in soup.find_all('a', href=True):
            href = a['href']
            sn = re.match(r'^cmake', href)
            es = href.endswith('.txt')
            if sn and es:
                resp = requests.get(url + '/' + href)
                resp.raise_for_status()
                sha256_files = resp.text.split('\n')
                macos_universal_versions = set()
                for line in sha256_files:
                    if is_matched(line):
                        sha256, filename = line.split()
                        if re.match(pattern, filename):
                            version, os, arch = re.match(pattern, filename).groups()
                        else:
                            continue
                        os = os.lower()
                        arch = arch.lower()
                        download_url = url + '/' + filename
                        
                        if os in ["macos","darwin"]:
                            if arch =="x86_64":
                                if version not in macos_universal_versions:
                                    releases["darwin"].append({'arch':'amd64','version': version, 'download_url': download_url, 'sha256': sha256})
                            elif arch == "universal":
                                releases["darwin"].append({'arch':'','version': version, 'download_url': download_url, 'sha256': sha256})
                                macos_universal_versions.add(version)
                        elif os in["windows","win32","win64"]:
                            if arch in ["x64", "x86_64"]:
                                releases["windows"].append({'arch':'amd64','version': version, 'download_url': download_url, 'sha256': sha256})
                            elif arch in ["i386", "x86"]:
                                releases["windows"].append({'arch':'386','version': version, 'download_url': download_url, 'sha256': sha256})
                            elif  arch == "arm64":
                                releases["windows"].append({'arch':'arm64','version': version, 'download_url': download_url, 'sha256': sha256})
                        elif os == "linux":
                            if arch in ["i386", "aarch64"]:
                                releases["linux"].append({'arch':'386','version': version, 'download_url': download_url, 'sha256': sha256})
                            elif arch == "x86_64":
                                releases["linux"].append({'arch':'amd64','version': version, 'download_url': download_url, 'sha256': sha256})
    with open("version.json", 'w', encoding="utf-8") as file:
        json.dump(releases, file, indent=4)

def is_matched(line):
    line = line.lower()
    return  any(sub in line for sub in ["macos", "darwin","windows", "win32", "win64","linux"]) and (line.endswith(".tar.gz") or line.endswith(".zip"))

if __name__ == "__main__":
    get_info()
