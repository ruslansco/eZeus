"""The gods float in the Godot city, so their held pose is a hover, not a stride. Godot-only: used by
tools/export_godot_pilot.py inside the disposable background export; the native art kit (art/characters/people)
is never edited and the SDL sprites keep walking.

The kit's god walk is `hero_walk(...)` called from each god's own `walk` closure with the god's props in its hands
(`people6.walker`, and the gods with their own walk). Rather than copy those closures, the hover is made by calling
the same closure with `people6.hero_walk` replaced for the call: the legs hang together and trail a little, the
body leans a little forward, the hands keep the god's own targets (so the staff, spear, bident, thunderbolt or
hammer stay in them) and everything drifts slowly over twelve frames, the held idle's loop (3 s at runtime).
The 24 walk samples the exporter writes are all the first frame of that loop: identical, so the optimizer merges them
and they cost one pose, not 24.
"""
import math
import sys

GODS = ['aphrodite', 'apollo', 'ares', 'artemis', 'athena', 'atlas', 'demeter', 'dionysus', 'hades', 'hephaestus', 'hera',
        'hermes', 'poseidon', 'zeus']
LOOP = 12
REVISION = 'floating_gods_v1'


def is_god(name):
    return name.removeprefix('walker_') in GODS and name.startswith('walker_')


def hover_pose(walk_fn):
    """A function frame -> pose of the god floating, for `frame` in 0..LOOP-1; returns the walk closure's hands."""
    people6 = sys.modules['people6']
    person_kit = sys.modules['person_kit']

    def pose_at(frame):
        t = (frame % LOOP) / LOOP
        ph = math.tau * t
        original = people6.hero_walk

        def float_walk(h, f, frames, cycles, **kw):
            hands = kw.get('hands')
            # The god's own hand targets, taken at a slowly changing phase so staff and arms drift a little.
            hand_phase = .5 + .30 * math.sin(ph)
            targets = hands(hand_phase) if callable(hands) else (hands or person_kit.free_hands(hand_phase))
            drop = kw.get('drop', .030)
            feet = {1: (.050, -.045 + .012 * math.sin(ph), .040 + .010 * math.sin(ph + .8)),
                    -1: (-.050, -.085 + .012 * math.sin(ph + math.pi), .014 + .008 * math.sin(ph + 2.0))}
            hips = (.004 * math.sin(ph), 0, h.pelvis_height - drop + .004 * math.cos(ph))
            lean = kw.get('lean', .015) + .020 + .005 * math.sin(ph)
            return hand_phase, person_kit.pose(h, hips, lean, feet, targets, turn=.020 * math.sin(ph))

        people6.hero_walk = float_walk
        try:
            return walk_fn(0)
        finally:
            people6.hero_walk = original
    return pose_at


def poses(walk_fn):
    """(pose, idle) for the exporter: 24 identical walk samples, a twelve-frame floating loop for the idle."""
    hover = hover_pose(walk_fn)
    return (lambda frame: hover(0)), (lambda frame: hover(frame))
