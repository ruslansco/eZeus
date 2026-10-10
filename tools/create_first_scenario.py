#!/usr/bin/env python3
"""Build a private fan-terrain adaptation without changing the installed catalog."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

REPO = Path(__file__).resolve().parents[1]
ROOT = REPO.parent
GODOT = ROOT / 'tools/godot-runtime/Godot.app/Contents/MacOS/Godot'
PLAN = REPO / 'content/scenarios/first_light_harbor_chapters.json'
BASE = REPO / 'build-content-research/first-light-harbor'
INSPECT = False


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None


def run_script(script, engine, report, args=(), headless=True, timeout=180):
    report.mkdir(parents=True, exist_ok=True)
    log = report / (Path(script).stem + '.log')
    env = os.environ.copy()
    env.update(EZEUS_SCENARIO_ENGINE=str(engine), EZEUS_SCENARIO_REPORT=str(report),
               EZEUS_SCENARIO_PLAN=str(PLAN),
               EZEUS_REVIEW_SETTINGS_PATH=str(report / 'settings.cfg'),
               EZEUS_REVIEW_SAVE_DIRECTORY=str(report / 'saves'),
               EZEUS_SCENARIO_MANIFEST=os.environ.get('EZEUS_SCENARIO_MANIFEST', str(BASE / 'current.json')))
    cmd = [str(GODOT), '--path', str(REPO / 'godot'), '--script', 'res://scripts/' + script,
           '--log-file', str(log)]
    if headless:
        cmd.append('--headless')
    else:
        cmd += ['--rendering-method', 'mobile', '--rendering-driver', 'metal']
    cmd += ['--', *args]
    with log.with_suffix('.console.log').open('w') as output:
        result = subprocess.run(cmd, cwd=REPO, env=env, stdout=output,
                                stderr=subprocess.STDOUT, timeout=timeout)
    text = log.read_text(errors='replace')
    for line in text.splitlines():
        if line.startswith('FIRST_SCENARIO_') or 'ERROR:' in line:
            print(line, flush=True)
    if result.returncode or 'ERROR:' in text:
        raise RuntimeError(f'Scenario step failed; see {log}')


def facade(path):
    engine = path / 'eZeus'
    engine.mkdir(parents=True, exist_ok=True)
    # Read-only compatibility resources; output/configuration directories are owned.
    for name in ['DATA', 'Audio', 'Model', 'Textures']:
        target = path / name
        if not target.exists():
            target.symlink_to(ROOT / name, target_is_directory=True)
    for name in ['text', 'fonts', 'Sanctuaries', 'Pyramids', 'textureTemplates']:
        if (REPO / name).exists() and not (engine / name).exists():
            (engine / name).symlink_to(REPO / name, target_is_directory=True)
    for name in ['Zeus_Text.xml', 'Zeus_MM.xml', 'Zeus_Text_ru.xml', 'Zeus_MM_ru.xml',
                 'interface.e', 'i15.e', 'i30.e', 'i45.e', 'i60.e']:
        if (REPO / name).exists() and not (engine / name).exists():
            (engine / name).symlink_to(REPO / name)
    if not (engine / 'numbers.txt').exists():
        shutil.copy2(REPO / 'numbers.txt', engine / 'numbers.txt')
    for folder in [engine / 'Adventures', engine / 'Bin', path / 'Adventures']:
        folder.mkdir(exist_ok=True)
    return engine


def text_file(fields):
    for key, value in fields.items():
        if key in ['parent_name', 'partner_name', 'leader']:
            continue
        if '"' in value:
            raise ValueError('Native campaign text cannot contain literal double quotes')
        yield f'{key}="{value}"\n'


def build():
    plan = json.loads(PLAN.read_text())
    current = BASE / 'current.json'
    if current.exists():
        previous = json.loads(current.read_text())
        if plan['id'] == 'first_light_harbor_chapters' and previous['version'] <= 3:
            legacy = BASE / 'single-chapter.json'
            if not legacy.exists():
                legacy.write_text(current.read_text())
    register = json.loads((REPO / 'docs/custom-adventures.provenance.json').read_text())
    record = next(r for r in register['records'] if r['id'] == plan['source_record'])
    source_key = next(key for key in record['reviewed_sha256_by_file'] if key.endswith('.pak'))
    reviewed = REPO / source_key
    source = REPO / 'build-content-research/working-copy' / plan.get('source_working_copy', 'alexandria')
    if not source.exists():
        source.mkdir(parents=True)
        for key, value in record['reviewed_sha256_by_file'].items():
            original = REPO / key
            if original.parent == reviewed.parent:
                if digest(original) != value:
                    raise RuntimeError('Reviewed source differs from provenance: ' + key)
                shutil.copy2(original, source / original.name)
    source_pak = source / reviewed.name
    expected = record['reviewed_sha256_by_file'][source_key]
    if digest(source_pak) != expected:
        raise RuntimeError('Scenario source differs from the reviewed input')
    stage = BASE / ('build-' + str(time.time_ns()))
    engine = facade(stage)
    source_names = [reviewed.name, reviewed.with_suffix('.txt').name]
    for name in source_names:
        key = str(reviewed.with_name(name).relative_to(REPO))
        if digest(source / name) != record['reviewed_sha256_by_file'][key]:
            raise RuntimeError('Working input differs from reviewed source: ' + name)
        shutil.copy2(source / name, stage / 'Adventures' / name)
    report = stage / 'report'
    report.mkdir()
    enum = (REPO / 'buildings/ebuilding.h').read_text(encoding='utf-8-sig')
    body = re.search(r'enum class eBuildingType\s*\{(.*?)\};', enum, re.S).group(1)
    body = re.sub(r'//[^\n]*|/\*.*?\*/', '', body, flags=re.S)
    building_types = {}
    value = 0
    for entry in body.split(','):
        entry = entry.strip()
        if not entry:
            continue
        parts = entry.split('=')
        if len(parts) > 1:
            value = int(parts[1].strip())
        building_types[parts[0].strip()] = value
        value += 1
    (report / 'building-types.json').write_text(json.dumps(building_types))
    run_script('create_first_scenario.gd', engine, report, [] if INSPECT else ['--build'])
    if INSPECT:
        print('Source inspection: ' + str(report), flush=True)
        return
    campaign = engine / 'Adventures' / plan['development_name']
    for lang, fields in plan['text'].items():
        suffix = '_ru' if lang == 'ru' else ''
        (campaign / (plan['development_name'] + suffix + '.txt')).write_text(''.join(text_file(fields)))
    (campaign / 'ATTRIBUTION.md').write_text(
        '# Private development adaptation\n\nParent terrain/world adapted from ' + record['notes']['title'] + ' by ' + record['creator'] + '.\n'
        'Source: ' + record['upstream_url_and_revision']['url'] + '\n'
        'Original archive SHA-256: ' + record['upstream_url_and_revision']['archive_sha256'] + '\n\n'
        'New settlement briefings, goals, partner settings and challenge: local project development, '
        'October 2026. Commercial redistribution permission remains unestablished; '
        'this scenario is excluded from release packaging.\n')
    # The probe's original PAKs no longer participate in this isolated play catalog.
    for name in source_names:
        (stage / 'Adventures' / name).unlink()
    manifest = {'id': plan['id'], 'version': plan['version'], 'source_record': plan['source_record'],
                'source_pak_sha256': expected, 'plan_sha256': digest(PLAN), 'engine': str(engine),
                'campaign': str(campaign), 'report': str(report), 'ships_in_release': False,
                'rights_status': 'needs_evidence', 'files': {f.name: digest(f) for f in campaign.iterdir() if f.is_file()}}
    terrain = json.loads((report / 'adapted-terrain.json').read_text())
    tiles = {(int(t[0]), int(t[1])): t for t in terrain['tiles']}
    candidates = [t for t in terrain['tiles'] if t[5] and int(t[2]) == 0][::12]
    best = None
    for tile in candidates:
        x, y = int(tile[0]), int(tile[1])
        area = [tiles.get((x+dx, y+dy)) for dx in range(-14, 15) for dy in range(-14, 15)]
        meadow = sum(bool(t and int(t[3]) & 8) for t in area)
        forest = sum(bool(t and int(t[3]) & 16) for t in area)
        ground = sum(bool(t and t[5] and int(t[2]) == 0) for t in area)
        if meadow >= 30 and forest >= 30 and ground >= 300:
            score = ground + min(meadow, 120) + min(forest, 120) - .3*abs(y-70)
            if best is None or score > best[0]:
                best = (score, x, y)
    if best is None and not plan.get('start_focus'):
        raise RuntimeError('No suitable initial presentation view near meadow/forest')
    manifest['start_focus'] = list(best[1:]) if best else plan['start_focus']
    if plan.get('start_focus'):
        if tuple(plan['start_focus']) not in tiles:
            raise RuntimeError('Authored focus is outside the native map')
        manifest['start_focus'] = plan['start_focus']
    (stage / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (BASE / 'current.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('Built private scenario: ' + str(campaign))


def main():
    global PLAN, BASE, INSPECT
    parser = argparse.ArgumentParser()
    parser.add_argument('--build', action='store_true')
    parser.add_argument('--inspect', action='store_true', help='Inspect a private source copy without authoring or replacing current.json')
    parser.add_argument('--plan', type=Path, help='Scenario recipe under content/scenarios; defaults to First Light chapters')
    parser.add_argument('--review', action='store_true')
    parser.add_argument('--visible', action='store_true')
    parser.add_argument('--play', action='store_true')
    parser.add_argument('--previous', action='store_true', help='Continue the preserved single-chapter prototype')
    parser.add_argument('--regressions', action='store_true')
    parser.add_argument('--unlock-review', action='store_true')
    parser.add_argument('--playthrough', action='store_true')
    parser.add_argument('--lang', choices=['en', 'ru'])
    args = parser.parse_args()
    INSPECT = args.inspect
    if args.plan:
        PLAN = args.plan.resolve()
        if PLAN.parent != REPO / 'content/scenarios' or PLAN.suffix != '.json':
            raise ValueError('Recipes must be JSON files under content/scenarios')
        plan = json.loads(PLAN.read_text())
        slug = plan['workspace_slug']
        if not re.fullmatch(r'[a-z][a-z0-9-]*', slug):
            raise ValueError('Invalid scenario workspace slug')
        BASE = REPO / 'build-content-research' / slug
    else:
        plan = json.loads(PLAN.read_text())
    if args.previous and args.plan:
        raise ValueError('--previous is reserved for the preserved First Light prototype')
    protected = [REPO / 'Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez', REPO / 'settings.txt',
                 ROOT / 'settings.txt', Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
    register = json.loads((REPO / 'docs/custom-adventures.provenance.json').read_text())
    for record in register['records']:
        for key, expected in record['reviewed_sha256_by_file'].items():
            original = REPO / key
            if digest(original) != expected:
                raise RuntimeError('Protected research input differs from provenance: ' + key)
            protected.append(original)
    # Authoring another adventure must not disturb First Light's content or saves.
    for slug in ['first-light-harbor','bronze-river','stonewatch','sunlit-terraces','tidebound-covenant']:
        first = REPO / 'build-content-research' / slug
        if BASE == first:
            continue
        protected += list((first / 'play').rglob('*'))
        for name in ['current.json', 'single-chapter.json']:
            path = first / name
            if path.exists():
                protected.append(path)
                previous = json.loads(path.read_text())
                protected += [Path(previous['campaign']) / f for f in previous['files']]
    # A running earlier launcher may append diagnostic logs. Protect actual
    # saves/settings/content, while allowing those live process logs to grow.
    protected = [path for path in protected if not path.is_dir() and path.suffix != '.log']
    before = {p: digest(p) for p in protected}
    BASE.mkdir(parents=True, exist_ok=True)
    try:
        if args.build or args.inspect:
            build()
        if args.inspect:
            return
        manifest_path = BASE / ('single-chapter.json' if args.previous else 'current.json')
        manifest = json.loads(manifest_path.read_text())
        campaign = Path(manifest['campaign'])
        if not args.previous and digest(PLAN) != manifest['plan_sha256']:
            raise RuntimeError('Scenario recipe changed; rebuild the prototype before playing/reviewing it')
        if any(digest(campaign / name) != value for name, value in manifest['files'].items()):
            raise RuntimeError('Scenario differs from its build manifest; rebuild or record the edit')
        if args.review:
            language = args.lang or 'en'
            report = Path(manifest['report']) / ('review-' + language + ('-visible' if args.visible else ''))
            run_script(plan.get('review_script', 'review_first_chapters.gd'), Path(manifest['engine']), report,
                       ['--lang=' + language] + (['--visible'] if args.visible else []), not args.visible, 240)
        if args.regressions:
            for script in ['validate_editor.gd', 'validate_embedded.gd']:
                report = BASE / ('retained-' + Path(script).stem)
                run_script(script, REPO, report, timeout=240)
                print('Retained check completed: ' + script, flush=True)
        if args.unlock_review:
            language = args.lang or 'en'
            report = Path(manifest['report']) / ('episode-unlocks-' + language)
            run_script('validate_episode_buildings.gd', Path(manifest['engine']), report,
                       ['--lang=' + language], timeout=240)
            result = json.loads((report / 'result.json').read_text())
            print('Episode unlocks: %s; %d checks; %s' % ('PASS' if result['okay'] else 'FAIL', result['checks'], language), flush=True)
            if not result['okay']:
                raise RuntimeError('Episode-building progression failed')
        if args.playthrough:
            report = Path(manifest['report']) / 'natural-playthrough'
            if report.exists():
                report.rename(report.with_name('natural-playthrough-attempt-' + str(time.time_ns())))
            run_script(plan.get('playthrough_script', 'playthrough_first_scenario.gd'), Path(manifest['engine']), report,
                       timeout=600)
            result = json.loads((report / 'result.json').read_text())
            print('Natural settlement playthrough: ' + ('PASS' if result['okay'] else 'FAIL'), flush=True)
            if not result['okay']:
                raise RuntimeError('Natural settlement progression failed: ' + str(report))
        if args.play:
            os.environ['EZEUS_SCENARIO_MANIFEST'] = str(manifest_path)
            play_root = BASE / 'play' if args.previous else BASE / 'play' / plan.get('profile_namespace', 'chapters')
            run_script('play_first_scenario.gd', Path(manifest['engine']), play_root,
                       ['--lang=' + args.lang] if args.lang else [], False, None)
    finally:
        changed = [str(p) for p in protected if digest(p) != before[p]]
        if changed:
            raise RuntimeError('Protected files changed: ' + ', '.join(changed))


if __name__ == '__main__':
    main()
