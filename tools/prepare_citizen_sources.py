#!/usr/bin/env python3
"""Fetch pinned MPFB + CC0 assets into the art workspace, without installing globally."""
import hashlib,json,urllib.request,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]/'art/characters/citizen_v2/vendor'
SOURCES=[('mpfb-v2.0.17.zip','https://codeload.github.com/makehumancommunity/mpfb2/zip/refs/tags/v2.0.17'),('makehuman_system_assets_cc0.zip','https://files2.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip')]
def main():
    ROOT.mkdir(parents=True,exist_ok=True)
    pinned=json.loads((Path(__file__).with_name('citizen_sources.json')).read_text())
    for name,url in SOURCES:
        path=ROOT/name
        if not path.exists():
            temp=path.with_suffix('.download');urllib.request.urlretrieve(url,temp);temp.rename(path)
        digest=hashlib.sha256(path.read_bytes()).hexdigest()
        expected=next(x['sha256'] for x in pinned if x['file']==name)
        if digest!=expected:raise RuntimeError('Source hash mismatch: '+name)
        dest=ROOT/name.removesuffix('.zip')
        if not dest.exists():
            with zipfile.ZipFile(path) as archive:
                for entry in archive.infolist():
                    if not (dest/entry.filename).resolve().is_relative_to(dest.resolve()):raise RuntimeError('Unsafe archive member')
                archive.extractall(dest)
        print(name,digest)
    (ROOT/'downloads.json').write_text(json.dumps(pinned,indent=2))
if __name__=='__main__':main()
