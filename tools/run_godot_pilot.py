#!/usr/bin/env python3
"""Isolated native-core + Godot session. Never writes the player's saved city."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import time

REPO = Path(__file__).resolve().parents[1]
ROOT = REPO.parent
GODOT = ROOT / 'tools/godot-runtime/Godot.app/Contents/MacOS/Godot'
SAVE = REPO / 'Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez'


def fingerprint(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def request(port, command='snapshot'):
    with socket.create_connection(('127.0.0.1', port), timeout=3) as connection:
        connection.sendall((command + '\n').encode())
        if command == 'quit':
            return None
        result = b''
        while b'\n' not in result:
            block = connection.recv(65536)
            if not block:
                raise RuntimeError('Native core disconnected')
            result += block
        return json.loads(result.split(b'\n')[0])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--legacy-bridge', action='store_true')
    parser.add_argument('--port', type=int, default=0)
    parser.add_argument('--lang', choices=['en', 'ru'], help='Interface language; unset opens the start menu in the player\'s saved language (automated runs default to en)')
    parser.add_argument('--core-only', action='store_true')
    parser.add_argument('--validate', action='store_true')
    parser.add_argument('--skip-start', action='store_true', help='Open the designated test city directly instead of the start menu')
    parser.add_argument('--asset-review', action='store_true', help='Capture the city models from four orbit angles, then exit')
    parser.add_argument('--garden-review', choices=['before', 'after'], help='Capture native ornamental gardens from four orbit angles, then exit')
    parser.add_argument('--sanctuary-review', help='Capture the designated city\'s sanctuaries from several angles into captures/sanctuary-<name>-*.png, then exit')
    parser.add_argument('--pyramid-review', help='Capture the designated city\'s pyramids from several angles into captures/pyramid-<name>-*.png, then exit')
    parser.add_argument('--start-review', choices=['leaders'], help='Capture the start menu\'s roster of leaders in a scratch profile, then The Sands of Betrayal\'s city for sale and the city menu (captures/start-review-*, menu-rest-cities-*), then exit')
    parser.add_argument('--menu-rest-review', choices=['menu', 'build', 'city', 'naval', 'anim'], help='Capture the Build menu trays that gained the rest of the SDL buildings, or build each new kind and capture it (captures/menu-rest-*.png), then exit')
    parser.add_argument('--objectives-review', help='Capture the objectives panel closed, open and with a sample housing shortfall into captures/objectives-<name>-*.png, then exit')
    parser.add_argument('--controls-review', help='Capture the Controls and Game settings dialogs into captures/controls-<name>-*.png, then exit')
    parser.add_argument('--rite-review', help='Capture the rite on a sanctuary altar (sheep, bull, goods) in the designated city into captures/rite-<name>-*.png, then exit')
    parser.add_argument('--attack-review', help='Capture a finished sanctuary\'s God Invasion offer in The Sands of Betrayal into captures/attack-<name>-*.png, then exit')
    parser.add_argument('--character-review', choices=['before', 'after'], help='Capture matched character portraits, poses and city pedestrians, then exit')
    parser.add_argument('--character-subjects', nargs='+', help='Optionally review only these model IDs')
    parser.add_argument('--terrain-review', choices=['before', 'after', 'elevation-before', 'elevation-after', 'detail-before', 'detail-after', 'polish-after', 'mineral-before', 'mineral-after', 'road-before', 'road-after'], help='Capture terrain at fixed positions/angles, then exit')
    parser.add_argument('--capture', type=Path)
    parser.add_argument('--headless', action='store_true')
    parser.add_argument('--renderer', choices=['metal', 'compatibility'], default='metal')
    args = parser.parse_args()
    if args.core_only:
        args.legacy_bridge = True
    if not GODOT.is_file() or not SAVE.is_file():
        raise SystemExit('Godot runtime or designated test city is missing. See godot/README.md.')
    captures = REPO / 'godot/captures'
    captures.mkdir(parents=True, exist_ok=True)
    # Absolute path: Godot interprets relative log paths under user://.
    engine_log = str(captures / 'session-engine.log')
    protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt']
    before = {p: fingerprint(p) for p in protected}
    if not args.legacy_bridge:
        library = REPO / 'godot/bin/libezeus_godot.dylib'
        if not library.is_file():
            raise SystemExit('Embedded simulation library is missing. Run tools/build_godot_extension.sh.')
        command = [str(GODOT), '--path', str(REPO / 'godot'), '--log-file', engine_log]
        command += ['--rendering-method', 'mobile', '--rendering-driver', 'metal'] if args.renderer == 'metal' else ['--rendering-method', 'gl_compatibility']
        if args.headless:
            command.append('--headless')
        automated = args.skip_start or args.validate or args.asset_review or args.garden_review or args.sanctuary_review or args.pyramid_review or args.menu_rest_review or args.start_review or args.controls_review or args.objectives_review or args.attack_review or args.rite_review or args.character_review or args.terrain_review or args.capture
        language = args.lang or ('en' if automated else None)
        command.append('--')
        if language:
            command.append(f'--lang={language}')
        if args.skip_start:
            command.append('--skip-start')
        if args.validate:
            command.append('--validate')
        if args.asset_review:
            command.append('--asset-review')
        if args.garden_review:
            command.append('--garden-review=' + args.garden_review)
        if args.sanctuary_review:
            command.append('--sanctuary-review=' + args.sanctuary_review)
        if args.pyramid_review:
            command.append('--pyramid-review=' + args.pyramid_review)
        if args.menu_rest_review:
            command.append('--menu-rest-review=' + args.menu_rest_review)
        if args.start_review:
            command.append('--start-review=' + args.start_review)
        if args.controls_review:
            command.append('--controls-review=' + args.controls_review)
        if args.objectives_review:
            command.append('--objectives-review=' + args.objectives_review)
        if args.attack_review:
            command.append('--attack-review=' + args.attack_review)
        if args.rite_review:
            command.append('--rite-review=' + args.rite_review)
        if args.character_review:
            command.append('--character-review=' + args.character_review)
        if args.character_subjects:
            command.append('--character-subjects=' + ','.join(args.character_subjects))
        if args.terrain_review:
            command.append('--terrain-review=' + args.terrain_review)
        if args.capture:
            args.capture.parent.mkdir(parents=True, exist_ok=True)
            command.append('--capture=' + str(args.capture.resolve()))
        env = {k: v for k, v in os.environ.items() if not k.startswith('EZEUS_')}
        try:
            print('Starting Godot with embedded C++ simulation; no SDL process.', flush=True)
            result = subprocess.run(command, cwd=REPO, env=env)
            if result.returncode:
                raise RuntimeError(f'Godot exited with status {result.returncode}')
        finally:
            for path, digest in before.items():
                if fingerprint(path) != digest:
                    raise RuntimeError(f'Protected file changed: {path}')
            print('Session closed; test save and settings are unchanged.', flush=True)
        return
    port = args.port
    if not port:
        with socket.socket() as reservation:
            reservation.bind(('127.0.0.1', 0))
            port = reservation.getsockname()[1]
    with tempfile.TemporaryDirectory(prefix='ezeus-godot-') as session:
        env = {k: v for k, v in os.environ.items() if not k.startswith('EZEUS_')}
        env.update(EZEUS_SHOT=f'{SAVE};{session}/unused.png;1',
                   EZEUS_3D_PORT=str(port), EZEUS_MENU_SHOT_SIZE='800x600')
        log_path = Path(session) / 'core.log'
        with log_path.open('w') as log:
            core = subprocess.Popen([str(REPO / 'Bin/eZeus')], cwd=REPO, env=env,
                                    stdout=log, stderr=subprocess.STDOUT)
            try:
                deadline = time.monotonic() + 90
                while True:
                    if core.poll() is not None:
                        raise RuntimeError('Native core failed:\n' + log_path.read_text()[-5000:])
                    try:
                        state = request(port)
                        if state.get('protocol') == 1:
                            break
                    except (OSError, RuntimeError):
                        pass
                    if time.monotonic() >= deadline:
                        raise RuntimeError('Native core did not finish loading the test city')
                    time.sleep(.2)
                fixture = REPO / 'godot/data/test_city.json'
                fixture.parent.mkdir(parents=True, exist_ok=True)
                fixture.write_text(json.dumps(state))
                print(f'Native core ready on 127.0.0.1:{port}; {len(state["buildings"])} buildings, '
                      f'{len(state["walkers"])} walkers. Test city is paused.', flush=True)
                if args.core_only:
                    while core.poll() is None:
                        time.sleep(.2)
                else:
                    if args.validate:
                        subprocess.run(['/usr/bin/python3', str(REPO / 'tools/validate_3d_bridge.py'),
                                        '--port', str(port)], cwd=REPO, check=True)
                    command = [str(GODOT), '--path', str(REPO / 'godot'), '--log-file', engine_log]
                    if args.renderer == 'metal':
                        command += ['--rendering-method', 'mobile', '--rendering-driver', 'metal']
                    else:
                        command += ['--rendering-method', 'gl_compatibility']
                    if args.headless:
                        command.append('--headless')
                    command += ['--', f'--bridge-port={port}', f'--lang={args.lang or "en"}']
                    if args.validate:
                        command.append('--validate')
                    if args.capture:
                        args.capture.parent.mkdir(parents=True, exist_ok=True)
                        command.append('--capture=' + str(args.capture.resolve()))
                    result = subprocess.run(command)
                    if result.returncode:
                        raise RuntimeError(f'Godot exited with status {result.returncode}')
            finally:
                if core.poll() is None:
                    try:
                        request(port, 'quit')
                        core.wait(timeout=5)
                    except (OSError, subprocess.TimeoutExpired):
                        core.terminate()
                        try:
                            core.wait(timeout=5)
                        except subprocess.TimeoutExpired:
                            core.kill()
                            core.wait()
                for path, digest in before.items():
                    if fingerprint(path) != digest:
                        raise RuntimeError(f'Protected file changed: {path}')
                print('Session closed; test save and settings are unchanged.', flush=True)


if __name__ == '__main__':
    main()
