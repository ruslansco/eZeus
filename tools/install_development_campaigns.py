#!/usr/bin/env python3
"""Install only verified private campaign exports; never edits saves or sources."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile

REPO = Path(__file__).resolve().parents[1]
RECIPES = [('first-light-harbor', 'first_light_harbor_chapters.json'),
           ('bronze-river', 'bronze_river_chapters.json'),
           ('stonewatch', 'stonewatch_chapters.json'),
           ('sunlit-terraces', 'sunlit_terraces_chapters.json'),
           ('tidebound-covenant', 'tidebound_covenant_chapters.json')]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None


def install(manifest_path, owned):
    manifest = json.loads(manifest_path.read_text())
    source = Path(manifest['campaign'])
    name = source.name
    if '/' in name or '\\' in name or name.startswith('.'):
        raise ValueError('Unsafe campaign identity')
    if any(digest(source / f) != h for f, h in manifest['files'].items()):
        raise ValueError('Export differs from reviewed manifest: ' + name)
    allowed = {name + '.epak', name + '.txt', name + '_ru.txt', 'ATTRIBUTION.md'}
    if set(manifest['files']) != allowed:
        raise ValueError('Unexpected export files: ' + name)
    destination = REPO / 'Adventures' / name
    archived = None
    if destination.exists():
        actual = {f.name: digest(f) for f in destination.iterdir() if f.is_file()}
        if actual == manifest['files'] and not any(f.is_dir() for f in destination.iterdir()):
            owned[name] = actual
            return manifest
        if name not in owned or actual != owned[name]:
            raise ValueError('Existing campaign has local changes; preserved: ' + name)
        # Keep a recoverable owned previous export instead of overwriting it.
        archived = destination.with_name('.' + name + '-previous')
        if archived.exists():
            raise ValueError('Previous export already exists; preserved both versions')
    with tempfile.TemporaryDirectory(prefix='.campaign-install-', dir=destination.parent) as temporary:
        stage = Path(temporary) / name
        shutil.copytree(source, stage)
        if any(digest(stage / f) != h for f, h in manifest['files'].items()):
            raise ValueError('Staged campaign copy differs')
        if archived is not None:
            destination.rename(archived)
        try:
            os.replace(stage, destination)
        except OSError:
            if archived is not None and not destination.exists():
                archived.rename(destination)
            raise
    owned[name] = manifest['files']
    return manifest


def main():
    evidence = REPO / 'build-content-research/campaign-library'
    evidence.mkdir(parents=True, exist_ok=True)
    record = evidence / 'installed.json'
    owned = json.loads(record.read_text()).get('files', {}) if record.exists() else {}
    entries = []
    for slug, recipe in RECIPES:
        path = REPO / 'content/scenarios' / recipe
        plan = json.loads(path.read_text())
        manifest_path = REPO / 'build-content-research' / slug / 'current.json'
        source_manifest = json.loads(manifest_path.read_text())
        if source_manifest['plan_sha256'] != digest(path):
            raise ValueError('Recipe is newer than its export: ' + recipe)
        manifest = install(manifest_path, owned)
        entries.append({'id': plan['id'], 'ref': plan['development_name'], 'featured': True,
                        'start_focus': manifest['start_focus'],
                        'art': 'res://assets/campaigns/' + slug.replace('-', '_') + '.png',
                        'hidden': False, 'ships_in_release': False, 'rights_status': 'needs_evidence',
                        'profile_roots': ['build-content-research/' + slug + '/play/' + plan.get('profile_namespace', 'chapters') + '/saves'],
                        'source_pak_sha256': manifest['source_pak_sha256'],
                        'title': {lang: text['Adventure_Title'] for lang, text in plan['text'].items()},
                        'chapters': {lang: [text['Parent_Episode_%d_Title' % (i+1)] for i in range(len(plan['chapters']))]
                                     for lang, text in plan['text'].items()}})
    legacy = REPO / 'build-content-research/first-light-harbor/single-chapter.json'
    if legacy.exists():
        manifest = install(legacy, owned)
        entries.append({'id': 'first_light_harbor_previous', 'ref': Path(manifest['campaign']).name,
                        'featured': False, 'hidden': True, 'ships_in_release': False, 'rights_status': 'needs_evidence',
                        'profile_roots': ['build-content-research/first-light-harbor/play/saves'],
                        'title': {'en': 'First Light Harbor (previous version)', 'ru': 'Первая гавань (предыдущая версия)'}, 'chapters': {}})
    index = {'schema_version': 1, 'purpose': 'Explicit private development library; no shipping clearance', 'campaigns': entries}
    for target, value in [(REPO / 'godot/data/development_campaigns.json', index),
                          (record, {'files': owned, 'ships_in_release': False})]:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=target.parent, delete=False) as stream:
            stream.write(json.dumps(value, ensure_ascii=False, indent=2) + '\n')
            temporary = Path(stream.name)
        os.replace(temporary, target)
    print('Installed verified development campaigns; originals and player files preserved.')


if __name__ == '__main__':
    main()
