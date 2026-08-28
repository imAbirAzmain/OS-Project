/* Path: mini_cloud/include/server.h */
#ifndef SERVER_H
#define SERVER_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <netinet/in.h>
#include <dirent.h>

#define DEFAULT_PORT 8080
#define BUFFER_SIZE 4096
#define MAX_QUOTA_BYTES (10 * 1024 * 1024)

// Standard CORS Headers for Web Browsers & Mobile Devices
#define CORS_HEADERS \
    "Access-Control-Allow-Origin: *\r\n" \
    "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n" \
    "Access-Control-Allow-Headers: Authorization, Content-Type\r\n"

typedef struct {
    char method[16];
    char path[256];
    char auth_token[128];
    long content_length;
} http_request_t;

// Core Engine Prototypes
int load_port_from_config(const char *config_path);
void setup_signal_handlers(void);
void handle_client_connection(int client_fd);

// User & Auth Prototypes
int validate_user_token(const char *token, char *out_username);
void handle_register(int client_fd, const char *raw_request);

// File I/O & Quotas
void parse_http_request(const char *raw_request, http_request_t *req);
void handle_file_download(int client_fd, const char *filepath);
void handle_file_upload(int client_fd, const char *filepath, const char *raw_request, ssize_t total_bytes_read);
long get_dir_size(const char *dirpath);

// Social & Messaging Engine
void handle_social_request(int client_fd, http_request_t *req, const char *raw_request);

#endif // SERVER_H
