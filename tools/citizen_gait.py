"""Periodic, distance-matched physician gait curves (Blender-independent).

Coordinates are the source rig's: -Y forward, Z up. A longer support phase gives
brief double support; the returning foot uses matching tangents at both contacts.
"""
import math

STRIDE = .64
RIG_SCALE = 1.045
STANCE = .56
CYCLE = .64


def ease(value):
    value = max(0.0, min(1.0, value))
    return value * value * (3 - 2 * value)


def foot(phase):
    p = phase % 1.0
    stride = STRIDE / RIG_SCALE
    span = stride * STANCE
    if p < STANCE:
        y = -span / 2 + stride * p
        clearance = 0.0
        pitch = -.12 * (1 - ease(p / .10)) + .28 * ease((p - .46) / .10)
    else:
        q = (p - STANCE) / (1 - STANCE)
        # Hermite return: a flat-foot linear stance joins the swing without a velocity snap.
        tangent = stride * (1 - STANCE)
        y = ((2*q**3 - 3*q*q + 1) * span/2
             + (q**3 - 2*q*q + q) * tangent
             + (-2*q**3 + 3*q*q) * -span/2
             + (q**3 - q*q) * tangent)
        clearance = .050 * math.sin(math.pi * q)**2
        pitch = .28 * (1 - ease(q)) - .12 * ease(q) - .12 * math.sin(math.pi*q)**2
    return y, clearance, pitch


def sole_contact(pitch, rest_y, rest_z):
    """Lowest point of the authored elliptical sandal relative to its ankle.

    Anchoring this point keeps heel contact and toe push-off above the floor. The
    same Y correction prevents the planted contact from sliding as the ankle rolls.
    """
    s, c = math.sin(pitch), math.cos(pitch)
    cy, cz = -.045 - rest_y, .006 - rest_z
    radius = math.hypot(.058*s, .006*c)
    y = cy - .058**2 * s / radius
    z = cz - .006**2 * c / radius
    return c*y - s*z, s*y + c*z


def body(phase):
    angle = math.tau * phase
    # Lowest at heel contact, highest as the body passes over the supporting leg.
    return (.004 * math.sin(angle), -.043 - .005 * math.cos(2*angle),
            -.027 * math.cos(angle), .012 * math.sin(angle))
