#include <stdio.h>
#include <stdint.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <utime.h>

int64_t linux_file_size(const char *filename) {
    struct stat st;

    if (stat(filename, &st) == 0)
        return (int64_t)st.st_size;

    return -1;
}

int64_t linux_file_mtime(const char *filename) {
    struct stat st;

    if (stat(filename, &st) == 0) {
        return st.st_mtime;

    }

    return -1;
}

int linux_update_mtime(const char* filename, int olderThan) {
    struct stat st;

    if (stat(filename, &st) != 0) {
        return -1;
    }

    int64_t m = st.st_mtime;
    time_t now = time(NULL);

    if (now - m < olderThan) {
        return 0;
    }

    struct utimbuf new_times;
    new_times.actime = st.st_atime;
    new_times.modtime = now;
    return utime(filename, &new_times) == 0 ? 1 : -1;
}
