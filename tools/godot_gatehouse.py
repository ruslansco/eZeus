"""Godot-only gatehouse model (5x2 tiles), composed after art/tower/build_sprites.py --gate has built one gate tower.

The native game draws a gatehouse as two side towers plus entrance sprites over a road passage. The Godot model keeps the
same Roman gate tower (art/gate_tower geometry, built by the unchanged source script) twice, a tile and a half either
side of the middle, and joins them with a vaulted passage under a wall walk: travertine piers and string course, brick
upper storey with a dedication panel, crenellated parapet. The passage runs along Blender +Y (tile y); the model is turned
a quarter for a gatehouse that is 2x5. The road itself is terrain, laid by the simulation, so the tunnel has no floor.

Geometry only, no random numbers; the source script and its materials are reused, nothing is written to art/.
"""
import math

import bpy
from mathutils import Vector

REVISION = 1
TOWER_X = 1.5        # tower centres, in tiles from the middle of the footprint
PLATFORM = 1.75      # the gate towers' platform
WALK = 1.35          # the wall walk over the passage: lower than the towers, so they stand clear of it
SPRING = .40         # height of the arch's springing line
RADIUS = .5          # the passage is one tile wide
STRING = .95         # string course, as on the tower


def _arc(radius, centre_z, steps=14):
    """Points on the upper half circle from x=-radius to x=+radius, as (x, z)."""
    return [(-radius * math.cos(math.pi * i / steps), centre_z + radius * math.sin(math.pi * i / steps)) for i in range(steps + 1)]


def _extrude_xz(outline, y0, y1):
    """Closed outline in the XZ plane pushed from y0 to y1: vertices and faces (outward normals) for MeshBatch.poly."""
    area = sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(outline, outline[1:] + outline[:1]))
    if area < 0:                                    # make it counter-clockwise as seen from -Y
        outline = outline[::-1]
    n = len(outline)
    verts = [(x, y0, z) for x, z in outline] + [(x, y1, z) for x, z in outline]
    faces = [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))]
    faces += [(i, n + i, n + (i + 1) % n, (i + 1) % n) for i in range(n)]
    return verts, faces


def compose(namespace):
    """Duplicate the gate tower to both ends and add the passage between them. `namespace` is the tower script's."""
    K, R, M = namespace['K'], namespace['R'], namespace['M']
    towers = [o for o in K.scene.objects if o.type == 'MESH' and o.parent == K.root]
    for ob in towers:
        twin = ob.copy()
        K.scene.collection.objects.link(twin)
        twin.location.x = TOWER_X
        ob.location.x = -TOWER_X
        twin.name = ob.name + ' east'

    B = R.Batches('Gatehouse')
    half = RADIUS
    for side in (-1, 1):                                                         # travertine piers either side of the passage
        B['trav'].box((side * (half + .25), 0, STRING / 2), (.5, 1.0, STRING))
    arch = _arc(half, SPRING)
    spandrel = [(-half, SPRING)] + arch[1:-1] + [(half, SPRING), (half, STRING), (-half, STRING)]
    B['trav'].poly(*_extrude_xz(spandrel, -.5, .5))                              # masonry over the vault
    ring = _arc(half + .13, SPRING) + _arc(half - .004, SPRING)[::-1]            # arch ring, proud of both faces and lining the vault
    B['marble'].poly(*_extrude_xz(ring, -.54, .54))
    for y in (-.54, .54):                                                        # keystone
        B['trav'].box((0, y, SPRING + half + .1), (.14, .06, .2))
    B['trav'].box((0, 0, STRING), (2.08, 1.08, .06))                             # string course across the bridge
    B['brick'].box((0, 0, STRING + .03 + (WALK - STRING - .03) / 2), (2.0, 1.0, WALK - STRING - .03))
    for y in (-1, 1):                                                            # gilt dedication panel on each face
        B['marble'].box((0, y * .503, 1.17), (.9, .01, .2))
        for k in range(9):
            B['gold'].box(((-.4 + k * .1), y * .509, 1.17 + (.04 if k % 2 else -.04)), (.05, .004, .05))
    B['trav'].box((0, 0, WALK + .02), (2.1, 1.16, .06))                      # cornice and floor of the wall walk
    B['trav'].box((0, 0, WALK + .055), (2.0, 1.08, .02))
    for y in (-1, 1):                                                            # merlons along both faces
        for k in range(6):
            p = Vector((-.9 + k * .36, y * .54, WALK + .12))
            B['brick'].box(p, (.12, .05, .13))
            B['trav'].box(p + Vector((0, 0, .072)), (.13, .06, .016))
    B.done()
    return towers
