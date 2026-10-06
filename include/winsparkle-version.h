

#ifndef _winsparkle_version_h_
#define _winsparkle_version_h_

/*--------------------------------------------------------------------------*
                         Version information
 *--------------------------------------------------------------------------*/

#define WIN_SPARKLE_VERSION_MAJOR   0
#define WIN_SPARKLE_VERSION_MINOR   6
#define WIN_SPARKLE_VERSION_MICRO   0

/**
    Checks if WinSparkle version is at least @a major.@a minor.@a micro.
 */
#define WIN_SPARKLE_CHECK_VERSION(major, minor, micro)           \
        (                                                        \
            WIN_SPARKLE_VERSION_MAJOR > (major)                  \
            ||                                                   \
            (WIN_SPARKLE_VERSION_MAJOR == (major) &&             \
             WIN_SPARKLE_VERSION_MINOR >= (minor))               \
            ||                                                   \
            (WIN_SPARKLE_VERSION_MAJOR == (major) &&             \
             WIN_SPARKLE_VERSION_MINOR == (minor) &&             \
             WIN_SPARKLE_VERSION_MICRO >= (micro))               \
        )

#define _WIN_SPARKLE_MAKE_STR(x) #x
#define _WIN_SPARKLE_MAKE_VERSION_STR(a,b,c) \
        _WIN_SPARKLE_MAKE_STR(a) "." _WIN_SPARKLE_MAKE_STR(b) "." _WIN_SPARKLE_MAKE_STR(c)

/**
    WinSparkle version as a string in the form of e.g. "0.1.3".
 */
#define WIN_SPARKLE_VERSION_STRING \
        _WIN_SPARKLE_MAKE_VERSION_STR(WIN_SPARKLE_VERSION_MAJOR, \
                                      WIN_SPARKLE_VERSION_MINOR, \
                                      WIN_SPARKLE_VERSION_MICRO)

#endif // _winsparkle_version_h_
