#!/usr/bin/env python3
"""Exercise original build rules in the designated, unsaved pilot session."""
import argparse
import json
import socket


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', required=True, type=int)
    args = parser.parse_args()
    with socket.create_connection(('127.0.0.1', args.port), timeout=8) as peer:
        stream = peer.makefile('rb')

        def command(text):
            peer.sendall((text + '\n').encode())
            return json.loads(stream.readline())

        checks = []

        def check(condition, label):
            checks.append({'check': label, 'pass': bool(condition)})
            print(('PASS ' if condition else 'FAIL ') + label)

        initial = command('snapshot')
        check(initial['protocol'] == 1 and initial['paused'], 'designated city is paused')
        check(command('build temple 0 0 0').get('error') is not None, 'invalid build is rejected')
        check(command('build road 99999 99999 0').get('error') == 'outside_district', 'district bounds are enforced')
        check(command('speed 99').get('error') == 'unsupported_command', 'invalid speed is rejected')
        before = command('snapshot')
        check(before['money'] == initial['money'] and before['buildings'] == initial['buildings'], 'invalid requests preserve city and treasury')
        hospital = next(b for b in before['buildings'] if b['asset'] == 'hospital')
        blocked = command(f'build house {hospital["x"]} {hospital["y"]} 1')
        check(blocked.get('money') == before['money'] and blocked.get('buildings') == before['buildings'], 'native rules reject occupied housing placement')
        for name, span, asset in [('road', 1, None), ('house', 2, 'common_house_0a'), ('hospital', 4, 'hospital'), ('fountain', 2, 'fountain')]:
            before = command('snapshot')
            tiles = {(t[0], t[1]): t for t in before['tiles']}
            candidate = None
            for (x, y), tile in tiles.items():
                if all((x + dx, y + dy) in tiles and tiles[x + dx, y + dy][5]
                       and not tiles[x + dx, y + dy][4] and tiles[x + dx, y + dy][2] == tile[2]
                       for dx in range(span) for dy in range(span)):
                    candidate = x, y
                    break
            check(candidate is not None, f'{name}: buildable footprint available')
            if candidate is None:
                continue
            x, y = candidate
            after = command(f'build {name} {x} {y} 2')
            if 'error' in after:
                check(False, f'{name}: {after["error"]}')
                continue
            if name == 'road':
                placed = next(t for t in after['tiles'] if t[:2] == [x, y])[4] == 1
            else:
                placed = any(b['asset'] == asset and b['x'] == x and b['y'] == y for b in after['buildings'])
            check(placed and after['money'] < before['money'], f'{name}: native construction and treasury charge')
        command('speed 2')
        check(command('snapshot')['speed'] == 2, 'speed changes reach native simulation')
        command('speed 0')
        check(command('snapshot')['time'] == initial['time'], 'construction while paused does not advance time')
        report = {'checks': checks, 'pass': all(c['pass'] for c in checks)}
        print('BRIDGE_VALIDATION ' + json.dumps(report))
        if not report['pass']:
            raise SystemExit(1)


if __name__ == '__main__':
    main()
