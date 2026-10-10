#!/usr/bin/env python3
"""Cross-platform, scratch-only large-city performance run. No player data writes."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import sys

REPO = Path(__file__).resolve().parents[1]
SAVE = REPO/'Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez'

def fingerprint(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None

def resident_memory_mib(pid):
    """Working set of this owned process, not the system or another game."""
    try:
        if os.name=='nt':
            import ctypes
            from ctypes import wintypes
            class Counters(ctypes.Structure):
                _fields_=[('cb',wintypes.DWORD),('faults',wintypes.DWORD)]+[(n,ctypes.c_size_t) for n in
                    ['peak_working','working','peak_paged','paged','peak_nonpaged','nonpaged','pagefile','peak_pagefile']]
            kernel=ctypes.WinDLL('kernel32',use_last_error=True)
            kernel.OpenProcess.argtypes=[wintypes.DWORD,wintypes.BOOL,wintypes.DWORD]
            kernel.OpenProcess.restype=wintypes.HANDLE
            kernel.CloseHandle.argtypes=[wintypes.HANDLE]
            psapi=ctypes.WinDLL('psapi',use_last_error=True)
            psapi.GetProcessMemoryInfo.argtypes=[wintypes.HANDLE,ctypes.POINTER(Counters),wintypes.DWORD]
            handle=kernel.OpenProcess(0x1000|0x10,False,pid)
            if not handle:return None
            try:
                values=Counters();values.cb=ctypes.sizeof(values)
                return values.working/1048576 if psapi.GetProcessMemoryInfo(handle,ctypes.byref(values),values.cb) else None
            finally:kernel.CloseHandle(handle)
        if sys.platform=='darwin':
            return float(subprocess.check_output(['ps','-o','rss=','-p',str(pid)],text=True))/1024
        for line in Path(f'/proc/{pid}/status').read_text().splitlines():
            if line.startswith('VmRSS:'):return float(line.split()[1])/1024
    except (OSError,ValueError,subprocess.SubprocessError):return None
    return None

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', type=Path, default=Path(os.environ.get('EZEUS_GODOT',str(REPO.parent/'tools/godot-runtime/Godot.app/Contents/MacOS/Godot'))))
    parser.add_argument('--headless', action='store_true')
    parser.add_argument('--width',type=int,default=1920)
    parser.add_argument('--height',type=int,default=1080)
    parser.add_argument('--phase-seconds', type=float, default=4)
    parser.add_argument('--soak-minutes', type=float, default=0)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if not args.godot.is_file() or not SAVE.is_file(): parser.error('Godot executable or designated fixture missing.')
    if not 1 <= args.phase_seconds <= 60 or not 0 <= args.soak_minutes <= 240: parser.error('Phase must be 1–60 seconds; soak 0–240 minutes.')
    if not 640<=args.width<=7680 or not 480<=args.height<=4320:parser.error('Choose a supported benchmark window size.')
    name = ('headless-' if args.headless else '')+'mobile'
    output = (args.output or REPO/f'godot/captures/release-performance-{name}.json').resolve()
    output.parent.mkdir(parents=True,exist_ok=True)
    log = output.with_suffix('.log')
    prefs = 'City Rebuild • 3D Pilot/settings.cfg'
    protected = [SAVE,REPO/'settings.txt',REPO.parent/'settings.txt',
                 Path.home()/'Library/Application Support/Godot/app_userdata'/prefs,
                 Path(os.environ.get('APPDATA',str(Path.home()/'AppData/Roaming')))/'Godot/app_userdata'/prefs,
                 Path.home()/'.local/share/godot/app_userdata'/prefs]
    before={p:fingerprint(p) for p in protected}
    process=None
    try:
        with tempfile.TemporaryDirectory(prefix='ezeus-release-perf-') as folder:
            env={k:v for k,v in os.environ.items() if not k.startswith('EZEUS_')}
            env.update(EZEUS_REVIEW_SETTINGS_PATH=str(Path(folder)/'settings.cfg'),
                       EZEUS_REVIEW_SAVE_DIRECTORY=str(Path(folder)/'saves'),
                       EZEUS_PERFORMANCE_REPORT=str(output),EZEUS_SEED='12345')
            command=[str(args.godot.resolve()),'--path',str(REPO/'godot'),'--rendering-method','mobile',
                     '--script','res://scripts/review_release_performance.gd','--log-file',str(log)]
            if os.name!='nt' and sys.platform=='darwin': command+=['--rendering-driver','metal']
            if args.headless:command.append('--headless')
            command+=['--','--silent','--lang=en',f'--phase-seconds={args.phase_seconds}',f'--soak-minutes={args.soak_minutes}',f'--width={args.width}',f'--height={args.height}']
            log.write_text('')
            process=subprocess.Popen(command,cwd=REPO,env=env,stdout=subprocess.DEVNULL,stderr=subprocess.STDOUT)
            deadline=time.monotonic()+240+args.phase_seconds*12+args.soak_minutes*60
            seen=0; memory=[]; next_memory=0
            while process.poll() is None:
                time.sleep(.2)
                lines=log.read_text(errors='replace').splitlines()
                for line in lines[seen:]:
                    if line.startswith('RELEASE_PERF'):print(line,flush=True)
                seen=len(lines)
                if time.monotonic()>=next_memory:
                    used=resident_memory_mib(process.pid)
                    if used is not None:memory.append(used)
                    next_memory=time.monotonic()+2
                if any('SCRIPT ERROR:' in line for line in lines) or time.monotonic()>deadline:
                    process.terminate();break
            process.wait(timeout=10)
            text=log.read_text(errors='replace')
            for line in text.splitlines()[seen:]:
                if line.startswith('RELEASE_PERF') or 'ERROR:' in line:print(line)
            verified=not process.returncode and 'RELEASE_PERFORMANCE_VALIDATION PASS' in text and 'ERROR:' not in text
            if output.is_file():
                data=json.loads(output.read_text())
                data['harness_verified']=verified
                data['engine_error_count']=sum('ERROR:' in line for line in text.splitlines())
                data['process_resident_memory_mib']={'available':bool(memory),'samples':len(memory),
                    'peak':max(memory) if memory else None,'last':memory[-1] if memory else None,
                    'scope':'owned Godot process working set; excludes private load-probe child and other applications'}
                data['passed']=bool(data.get('passed')) and verified
                output.write_text(json.dumps(data,indent=2)+'\n')
            if not verified:
                raise RuntimeError('Performance run failed; see '+str(log))
    finally:
        if process is not None and process.poll() is None:process.kill();process.wait()
        changed=[str(p) for p in protected if fingerprint(p)!=before[p]]
        if changed:raise RuntimeError('Protected files changed: '+', '.join(changed))
    print('Designated save and player preferences unchanged. Report: '+str(output))

if __name__=='__main__':main()
