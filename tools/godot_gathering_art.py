"""Godot-only timing adapter for the authored urchin collection cycle.

The native sprite source and simulation duration remain untouched. The dip is
brief enough to read through opaque water; recovery with the bag holds longer.
"""
KEYS = [(0.0,0.0),(.18,.07),(.34,.32),(.44,.65),(.62,.93),(.88,.96),(1.0,1.0)]

def native_phase(phase):
    phase=max(0.0,min(1.0,phase))
    for (a,x),(b,y) in zip(KEYS,KEYS[1:]):
        if phase <= b:
            t=(phase-a)/(b-a)
            t=t*t*t*(t*(t*6-15)+10)
            return x+(y-x)*t
    return 1.0

def retime_urchin(callback):
    return lambda frame: callback(native_phase(frame/40.0)*40.0)
