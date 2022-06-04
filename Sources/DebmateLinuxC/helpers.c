#include <stdio.h>
#include <stdint.h>
#include <sys/stat.h>
#include <sys/types.h>

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

