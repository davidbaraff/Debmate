#include <stdint.h>
int64_t linux_file_size(const char *filename);
int64_t linux_file_mtime(const char *filename);
int linux_update_mtime(const char* filename, int olderThan);
