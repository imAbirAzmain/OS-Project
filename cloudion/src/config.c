/* Path: mini_cloud/src/config.c */
#include "server.h"

// Reads PORT from config/server.conf using raw POSIX syscalls
int load_port_from_config(const char *config_path) {
    int fd = open(config_path, O_RDONLY);
    if (fd < 0) {
        perror("[!] Warning: Could not open config file. Defaulting to 8080");
        return DEFAULT_PORT;
    }

    char conf_buffer[512] = {0};
    ssize_t bytes_read = read(fd, conf_buffer, sizeof(conf_buffer) - 1);
    close(fd);

    if (bytes_read <= 0) {
        return DEFAULT_PORT;
    }

    // Parse "PORT=" key from buffer
    char *port_ptr = strstr(conf_buffer, "PORT=");
    if (port_ptr != NULL) {
        int parsed_port = atoi(port_ptr + 5);
        if (parsed_port > 0) {
            return parsed_port;
        }
    }

    return DEFAULT_PORT;
}
