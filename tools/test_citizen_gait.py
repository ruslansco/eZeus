"""Contact, loop and velocity gates for the authored gait; no Blender dependency."""
import math
import unittest
import citizen_gait as gait


class GaitTests(unittest.TestCase):
    def test_contact_follows_native_stride(self):
        # The rig is scaled on export. A planted contact counteracts the body's travel.
        for i in range(1, 560):
            p = i / 1000
            y, lift, pitch = gait.foot(p)
            cy, cz = gait.sole_contact(pitch, -.00835236255, .03328342363)
            flat_y, _ = gait.sole_contact(0, -.00835236255, .03328342363)
            ankle_y = y - (cy - flat_y)
            ankle_z = -cz + .0005 + lift
            self.assertAlmostEqual((ankle_y + cy - flat_y) * gait.RIG_SCALE - gait.STRIDE * p,
                                   -gait.STRIDE * gait.STANCE / 2, places=10)
            self.assertAlmostEqual(ankle_z + cz, .0005, places=10)

    def test_swing_clearance_and_double_support(self):
        double_support = 0
        for i in range(1000):
            p = (i + .5) / 1000
            _, left, _ = gait.foot(p)
            _, right, _ = gait.foot(p + .5)
            self.assertGreaterEqual(left, 0)
            self.assertGreaterEqual(right, 0)
            if left == right == 0: double_support += 1
        self.assertEqual(double_support, 120)
        self.assertAlmostEqual(gait.foot(gait.STANCE+(1-gait.STANCE)/2)[1], .050)

    def test_loops_and_contact_velocities_are_continuous(self):
        h = 1e-6
        for point in [0, gait.STANCE]:
            left = gait.foot(point-h);mid = gait.foot(point);right = gait.foot(point+h)
            for a, b in zip(left, right): self.assertLess(abs(a-b), 2e-6)
            for a, b, c in zip(left, mid, right):
                self.assertLess(abs((b-a)/h-(c-b)/h), .001)
        for a, b in zip(gait.body(0), gait.body(1)): self.assertAlmostEqual(a, b)


if __name__ == '__main__': unittest.main()
