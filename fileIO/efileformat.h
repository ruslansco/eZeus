#ifndef EFILEFORMAT_H
#define EFILEFORMAT_H

namespace eFileFormat {
    enum {
        initial,
        settlerEmigrant,
        cartTarget,
        cityHistory,
        messageLog,
        messageCategory,
        viewState,
        // The original game's stockpiling, Auto Defend, oracle consultations and trireme crews (the Zeus guide's features).
        zeusGuide,

        nextVersion
    };

    const int version = nextVersion - 1;
}

#endif // EFILEFORMAT_H
