#!/usr/bin/env python3
"""Export the character window's portrait models (Greek faces, curly hair and beards) in background Blender processes.

python3 tools/export_portraits.py [--assets walker_trader ...] [--jobs 2]

Writes godot/assets/portraits/<asset>.glb + .json for each walker with a grown Greek man (tools/godot_portrait_export.py);
assets without one are skipped. Never touches the crowd models; import with Godot afterwards.
"""
import argparse, concurrent.futures, json, subprocess, time
from pathlib import Path
from godot_asset_sources import PEOPLE

REPO = Path(__file__).resolve().parents[1]
BLENDER = Path('/Applications/Blender.app/Contents/MacOS/Blender')
FOREIGN = ('persian', 'egyptian', 'mayan', 'phoenician', 'oceanid', 'centaur', 'amazon')
WOMEN = {'aphrodite', 'artemis', 'athena', 'demeter', 'hera', 'atalanta', 'medusa', 'maenads', 'harpies', 'priestess'}
OTHER = {'hades', 'cyclops', 'talos', 'minotaur', 'satyr'}
NAMES = ['philosopher', 'physician', 'transporter', 'settlers1'] + ['walker_' + n for n in PEOPLE
         if n not in WOMEN | OTHER and not n.startswith(FOREIGN)]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--assets', nargs='+', choices=NAMES, default=NAMES)
    ap.add_argument('--jobs', type=int, choices=[1, 2, 3], default=2)
    ap.add_argument('--budget', type=int, default=26000)
    args = ap.parse_args()
    logs = REPO / 'godot/captures/portrait-exports'; logs.mkdir(parents=True, exist_ok=True)
    out = REPO / 'godot/assets/portraits'
    def run(name):
        start = time.monotonic()
        with (logs / (name + '.log')).open('w') as log:
            code = subprocess.run([str(BLENDER), '-b', '--factory-startup', '--python-exit-code', '1', '-P',
                                   str(REPO / 'tools/godot_portrait_export.py'), '--', '--asset', name, '--budget', str(args.budget)],
                                  cwd=REPO, stdout=log, stderr=subprocess.STDOUT).returncode
        result = {'asset': name, 'seconds': round(time.monotonic() - start, 1), 'exit_code': code}
        manifest = out / (name + '.json')
        if code == 0 and manifest.exists():
            report = json.loads(manifest.read_text())
            result.update(vertices=report['vertices'], bytes=report['bytes'], people=len(report['portrait']['people']))
        elif code == 3:
            result['skipped'] = 'no grown Greek man'
        else:
            result['error'] = 'see ' + str(logs / (name + '.log'))
        return result
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for future in concurrent.futures.as_completed([pool.submit(run, n) for n in args.assets]):
            results.append(future.result()); print(json.dumps(results[-1]), flush=True)
    (logs / 'rollout.json').write_text(json.dumps(sorted(results, key=lambda r: r['asset']), indent=2) + '\n')
    if any(r.get('error') for r in results): raise SystemExit(1)

if __name__ == '__main__': main()
