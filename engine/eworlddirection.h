#ifndef EWORLDDIRECTION_H
#define EWORLDDIRECTION_H

enum class eWorldDirection {
    N,
    W,
    S,
    E
};

// Direction order matches the existing compass arrows: left -1, right +1.
constexpr eWorldDirection eRotateWorldDirection(eWorldDirection dir, int turns) {
    return static_cast<eWorldDirection>((static_cast<int>(dir) + turns % 4 + 4) % 4);
}

#endif // EWORLDDIRECTION_H
