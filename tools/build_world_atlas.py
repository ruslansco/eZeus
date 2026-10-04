#!/usr/bin/env python3
"""Bake coordinate-preserving coast/relief data for the Godot regional atlas.

The clean Greece 08 plate has the same coastline as Greece 01-10, without the
foreground character illustration. Poseidon keeps its four distinct maps.
These are presentation fields, not geographic DEMs or simulation tiles.
Run with a Python containing Pillow and numpy; source plates remain untouched.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parents[1]
SOURCE = REPO.parent / 'Textures/Zeus_Data_Images'
OUT = REPO / 'godot/assets/world'


def blur(a, radius):
    im = Image.fromarray(np.uint8(np.clip(a, 0, 1)*255))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(radius)), dtype=float)/255


def noise(x, y, frequency, seed):
    """Continuous deterministic value noise, with local RNG only."""
    rng = np.random.default_rng(seed)
    grid = rng.random((128, 128))
    px, py = x*frequency+5, y*frequency+5
    ix, iy = np.floor(px).astype(int), np.floor(py).astype(int)
    fx, fy = px-ix, py-iy
    fx, fy = fx*fx*(3-2*fx), fy*fy*(3-2*fy)
    a = grid[iy%128, ix%128]*(1-fx)+grid[iy%128, (ix+1)%128]*fx
    b = grid[(iy+1)%128, ix%128]*(1-fx)+grid[(iy+1)%128, (ix+1)%128]*fx
    return a*(1-fy)+b*fy


def bake(name, filename):
    path = SOURCE/filename
    im = Image.open(path).convert('RGB')
    im.thumbnail((896, 896), Image.Resampling.LANCZOS)
    rgb = np.asarray(im, dtype=float)/255
    r, g, b = rgb.transpose(2, 0, 1)
    mask = ((g > b*1.04) & (r > b*.78)).astype(float)
    # Close one-pixel paint shadows without erasing the small Aegean islands.
    mask = np.asarray(Image.fromarray(np.uint8(mask*255)).filter(
        ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3)), dtype=float)/255
    h, w = mask.shape
    y, x = np.mgrid[0:h, 0:w]/float(w)
    # Warped ridged terrain creates irregular massifs and valleys, avoiding
    # repeating sine-wave rows. This is authored relief rather than survey data.
    wx = x+(noise(x,y,7,1701)-.5)*.14
    wy = y+(noise(x,y,7,1702)-.5)*.14
    ridge = np.zeros((h, w))
    weight = 0.0
    for i in range(5):
        amplitude = .52**i
        ridge += (1-np.abs(noise(wx,wy,7*2**i,1901+i)*2-1))*amplitude
        weight += amplitude
    ridge /= weight
    interior = blur(mask, 14)
    shore = blur(mask, 2)
    coverage = blur(mask, .65)
    massifs = noise(x,y,4,2101)
    relief = coverage*(.035 + interior**3*(.15+3.5*ridge**3*(.4+massifs)))
    # Submerged shoreline apron produces continuous banks, without high water
    # beneath land. Channel B is coast coverage; G is shallow water proximity.
    ecology = noise(x,y,19,2201)*.55+noise(x,y,43,2202)*.45
    fields = np.stack((np.clip(relief/3.6, 0, 1), shore, coverage, ecology), axis=-1)
    OUT.mkdir(parents=True, exist_ok=True)
    out = OUT/(name+'.png')
    Image.fromarray(np.uint8(fields*255), 'RGBA').save(out)
    return {'file': out.name, 'source': str(path.relative_to(REPO.parent)),
            'source_sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
            'sha256': hashlib.sha256(out.read_bytes()).hexdigest(),
            'width': w, 'height': h, 'aspect': im.width/im.height,
            'land_fraction': float(mask.mean()), 'height_scale': 3.6,
            'rights_status': 'needs_evidence'}


def main():
    records = {'greece': bake('greece', 'Zeus_MapOfGreece08.JPG')}
    for i in range(1, 5):
        records['poseidon%d'%i] = bake('poseidon%d'%i, 'Poseidon_map%02d.jpg'%i)
    manifest = {'revision': 'living_atlas_v1', 'generator': 'tools/build_world_atlas.py',
                'scope': 'Cosmetic 3D regional atlas; normalized native city coordinates unchanged.',
                'channels': 'R procedural relief / 3.6; G shore proximity; B coast coverage; A ecology',
                'projection': 'Native UV to curved regional globe patch. Relief is artistic, not a geographic DEM.',
                'maps': records, 'budgets': {'terrain_grid': [256, 226], 'clouds': 12,
                  'trees': 1600, 'decorative_ships': 7, 'mesh_instances_max': 100,
                  'triangles_max': 220000},
                'release_status': 'Development art; retained source plate rights need evidence.'}
    (OUT/'atlas_sources.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print('ATLAS_FIELDS', len(records), 'coast/relief maps; original plates untouched')


if __name__ == '__main__':
    main()
