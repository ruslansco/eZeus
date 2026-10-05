#!/usr/bin/env python3
"""Owned Hydra FX review: real native attack, designated save, disposable preferences."""
import argparse
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser = argparse.ArgumentParser()
parser.add_argument('--lang', choices=['en', 'ru'], default='en')
parser.add_argument('--record', action='store_true', help='Encode the native attack to MP4, or GIF with Pillow')
args = parser.parse_args()
protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
             Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before = {p: fingerprint(p) for p in protected}
log = REPO / f'godot/captures/monster-effects-{args.lang}-engine.log'
command = [str(GODOT), '--path', str(REPO / 'godot'), '--rendering-method', 'mobile', '--rendering-driver', 'metal',
           '--script', 'res://scripts/review_monster_effects.gd', '--log-file', str(log),
           '--', '--skip-start', '--silent', '--lang=' + args.lang]
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-monster-fx-') as directory:
        scratch = Path(directory)
        env = os.environ.copy()
        env['EZEUS_REVIEW_SETTINGS_PATH'] = str(scratch / 'settings.cfg')
        env['EZEUS_REVIEW_SAVE_DIRECTORY'] = str(scratch / 'saves')
        if args.record:
            frames = scratch / 'frames'
            frames.mkdir()
            env['EZEUS_FX_FRAME_DIRECTORY'] = str(frames)
        else:
            env.pop('EZEUS_FX_FRAME_DIRECTORY', None)
        result = subprocess.run(command, cwd=REPO, timeout=300, env=env,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        print(result.stdout, flush=True)
        text = log.read_text() if log.exists() else result.stdout
        if result.returncode or 'MONSTER_FX_REVIEW PASS' not in text or 'SCRIPT ERROR:' in text or 'ERROR:' in text:
            raise RuntimeError(f'Hydra review exited {result.returncode}; see {log}')
        if args.record:
            ffmpeg = shutil.which('ffmpeg')
            if ffmpeg:
                video = REPO / f'godot/captures/hydra-combat-{args.lang}.mp4'
                subprocess.run([ffmpeg, '-y', '-loglevel', 'error', '-framerate', '10', '-i', str(frames / '%04d.png'),
                                '-vf', 'scale=960:-2', '-c:v', 'libx264', '-crf', '20', '-pix_fmt', 'yuv420p',
                                '-movflags', '+faststart', str(video)], check=True)
            else:
                from PIL import Image
                video = REPO / f'godot/captures/hydra-combat-{args.lang}.gif'
                images = []
                for path in sorted(frames.glob('*.png')):
                    with Image.open(path) as image:
                        image.thumbnail((960, 600), Image.Resampling.LANCZOS)
                        images.append(image.convert('P', palette=Image.Palette.ADAPTIVE, colors=128))
                images[0].save(video, save_all=True, append_images=images[1:], duration=100, loop=0, optimize=False)
            print('Hydra combat recording: ' + str(video))
finally:
    changed = [str(p) for p in protected if before[p] != fingerprint(p)]
    if changed:
        raise RuntimeError('Protected files changed: ' + ', '.join(changed))
    print('Hydra review closed; designated save and player preferences unchanged.', flush=True)
