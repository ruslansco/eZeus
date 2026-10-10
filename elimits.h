#ifndef ELIMITS_H
#define ELIMITS_H

#if (defined (_WIN32) || defined (_WIN64)) && !defined(__INT_MAX__)
    #include <limits.h>

    #define __INT_MAX__ INT_MAX
#endif

#endif // ELIMITS_H
