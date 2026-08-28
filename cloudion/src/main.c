#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <arpa/inet.h>

void handle_file_upload(int client_fd, const char *username, const char *filename, const char *initial_body, size_t initial_body_len, size_t content_length);
void handle_file_list(int client_fd, const char *username);
void handle_file_download(int client_fd, const char *username, const char *filename);
int authenticate_user(const char *username, const char *password, char *out_token);
void handle_register(int client_fd, const char *raw_request);

void ensure_storage_dirs() {
    mkdir("storage", 0755);
    mkdir("storage/public", 0755);
    mkdir("storage/groups", 0755);
}

void url_decode(char *dst, const char *src) {
    char a, b;
    while (*src) {
        if ((*src == '%') && ((a = src[1]) && (b = src[2])) && (isxdigit(a) && isxdigit(b))) {
            if (a >= 'a' && a <= 'f') a -= 'a' - 'A';
            if (a >= 'A' && a <= 'F') a = a - 'A' + 10;
            else a -= '0';
            if (b >= 'a' && b <= 'f') b -= 'a' - 'A';
            if (b >= 'A' && b <= 'F') b = b - 'A' + 10;
            else b -= '0';
            *dst++ = 16 * a + b;
            src += 3;
        } else if (*src == '+') {
            *dst++ = ' ';
            src++;
        } else {
            *dst++ = *src++;
        }
    }
    *dst = '\0';
}

void get_query_param(const char *url, const char *param, char *output, size_t out_size) {
    output[0] = '\0';
    char search[128];
    snprintf(search, sizeof(search), "%s=", param);
    char *start = strstr(url, search);
    if (start) {
        start += strlen(search);
        char *end = strchr(start, '&');
        if (!end) end = strchr(start, ' ');
        if (!end) end = start + strlen(start);
        size_t len = end - start;
        char temp[256] = "";
        if (len >= sizeof(temp)) len = sizeof(temp) - 1;
        strncpy(temp, start, len);
        temp[len] = '\0';

        char decoded[256];
        url_decode(decoded, temp);
        strncpy(output, decoded, out_size - 1);
        output[out_size - 1] = '\0';
    }
}

size_t parse_content_length(const char *buffer) {
    const char *cl = strstr(buffer, "Content-Length: ");
    if (!cl) cl = strstr(buffer, "content-length: ");
    if (cl) return (size_t)atoll(cl + 16);
    return 0;
}

void get_user_from_token(const char *token, char *username) {
    if (strncmp(token, "token_", 6) == 0) {
        const char *start = token + 6;
        const char *end = strrchr(start, '_');
        if (end && end > start) {
            size_t len = end - start;
            strncpy(username, start, len);
            username[len] = '\0';
            return;
        }
    }
    strcpy(username, "guest");
}

void serve_html_file(int client_fd, const char *filepath) {
    FILE *fp = fopen(filepath, "r");
    if (!fp) {
        const char *err = "HTTP/1.1 404 Not Found\r\n\r\nPage not found";
        send(client_fd, err, strlen(err), 0);
        return;
    }
    fseek(fp, 0, SEEK_END);
    long sz = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    char *html = malloc(sz + 1);
    fread(html, 1, sz, fp);
    fclose(fp);
    html[sz] = '\0';

    char header[256];
    snprintf(header, sizeof(header), "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: %ld\r\n\r\n", sz);
    send(client_fd, header, strlen(header), 0);
    send(client_fd, html, sz, 0);
    free(html);
}

void handle_client(int client_fd) {
    char buffer[65536];
    ssize_t bytes_received = recv(client_fd, buffer, sizeof(buffer) - 1, 0);
    if (bytes_received <= 0) {
        close(client_fd);
        return;
    }
    buffer[bytes_received] = '\0';

    char method[16], raw_path[512];
    sscanf(buffer, "%s %s", method, raw_path);

    char clean_path[512];
    strncpy(clean_path, raw_path, sizeof(clean_path) - 1);
    clean_path[sizeof(clean_path) - 1] = '\0';
    char *qmark = strchr(clean_path, '?');
    if (qmark) *qmark = '\0';

    char token[128] = "";
    char *auth_hdr = strstr(buffer, "Authorization: ");
    if (auth_hdr) {
        sscanf(auth_hdr, "Authorization: %127s", token);
    } else {
        get_query_param(raw_path, "token", token, sizeof(token));
    }

    char username[64];
    get_user_from_token(token, username);

    // --- 1. WEB UI ROUTING ---
    if (strcmp(clean_path, "/") == 0 || strcmp(clean_path, "/login.html") == 0) {
        serve_html_file(client_fd, "web/login.html");
    } 
    else if (strcmp(clean_path, "/index.html") == 0) {
        serve_html_file(client_fd, "web/index.html");
    }
    // --- 2. AUTHENTICATION API ---
    else if (strcmp(clean_path, "/user/register") == 0) {
        handle_register(client_fd, buffer);
    } 
    else if (strcmp(clean_path, "/user/login") == 0) {
        char user[64], pass[64], out_token[128];
        get_query_param(raw_path, "user", user, sizeof(user));
        get_query_param(raw_path, "pass", pass, sizeof(pass));

        if (authenticate_user(user, pass, out_token)) {
            char resp[512];
            snprintf(resp, sizeof(resp), "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"success\",\"token\":\"%s\",\"user\":\"%s\"}", out_token, user);
            send(client_fd, resp, strlen(resp), 0);
        } else {
            const char *err = "HTTP/1.1 401 Unauthorized\r\nContent-Type: application/json\r\n\r\n{\"status\":\"error\",\"message\":\"Invalid user or password\"}";
            send(client_fd, err, strlen(err), 0);
        }
    }
    // --- 3. GROUP MANAGEMENT API ---
    else if (strcmp(clean_path, "/group/create") == 0) {
        char group_name[64];
        get_query_param(raw_path, "name", group_name, sizeof(group_name));
        if (strlen(group_name) > 0) {
            char group_dir[256], group_files_dir[256], members_file[256];
            snprintf(group_dir, sizeof(group_dir), "storage/groups/%s", group_name);
            snprintf(group_files_dir, sizeof(group_files_dir), "storage/groups/%s/files", group_name);
            mkdir(group_dir, 0755);
            mkdir(group_files_dir, 0755);

            snprintf(members_file, sizeof(members_file), "storage/groups/%s/members.txt", group_name);
            FILE *mf = fopen(members_file, "a");
            if (mf) {
                fprintf(mf, "%s\n", username);
                fclose(mf);
            }

            char resp[256];
            snprintf(resp, sizeof(resp), "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"success\",\"message\":\"Group '%s' created!\"}", group_name);
            send(client_fd, resp, strlen(resp), 0);
        } else {
            const char *err = "HTTP/1.1 400 Bad Request\r\n\r\nMissing group 'name' parameter";
            send(client_fd, err, strlen(err), 0);
        }
    }
    else if (strcmp(clean_path, "/group/add_user") == 0) {
        char group_name[64], target_user[64];
        get_query_param(raw_path, "group", group_name, sizeof(group_name));
        get_query_param(raw_path, "user", target_user, sizeof(target_user));

        if (strlen(group_name) > 0 && strlen(target_user) > 0) {
            struct stat st;
            char user_dir[256], group_dir[256], members_file[256];

            snprintf(user_dir, sizeof(user_dir), "storage/%s", target_user);
            if (stat(user_dir, &st) != 0 || !S_ISDIR(st.st_mode)) {
                const char *err = "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\n\r\n{\"status\":\"error\",\"message\":\"User ID does not exist!\"}";
                send(client_fd, err, strlen(err), 0);
                close(client_fd);
                return;
            }

            snprintf(group_dir, sizeof(group_dir), "storage/groups/%s", group_name);
            if (stat(group_dir, &st) != 0 || !S_ISDIR(st.st_mode)) {
                const char *err = "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\n\r\n{\"status\":\"error\",\"message\":\"Group does not exist!\"}";
                send(client_fd, err, strlen(err), 0);
                close(client_fd);
                return;
            }

            snprintf(members_file, sizeof(members_file), "storage/groups/%s/members.txt", group_name);
            FILE *mf = fopen(members_file, "a+");
            if (mf) {
                char existing[128];
                int exists = 0;
                fseek(mf, 0, SEEK_SET);
                while (fscanf(mf, "%127s", existing) == 1) {
                    if (strcmp(existing, target_user) == 0) {
                        exists = 1;
                        break;
                    }
                }

                if (!exists) {
                    fprintf(mf, "%s\n", target_user);
                    fclose(mf);
                    char resp[256];
                    snprintf(resp, sizeof(resp), "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"success\",\"message\":\"User '%s' added to group '%s'!\"}", target_user, group_name);
                    send(client_fd, resp, strlen(resp), 0);
                } else {
                    fclose(mf);
                    const char *err = "HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{\"status\":\"error\",\"message\":\"User is already in this group!\"}";
                    send(client_fd, err, strlen(err), 0);
                }
            } else {
                const char *err = "HTTP/1.1 500 Internal Error\r\n\r\nFailed to read group members";
                send(client_fd, err, strlen(err), 0);
            }
        } else {
            const char *err = "HTTP/1.1 400 Bad Request\r\n\r\nMissing group or user parameter";
            send(client_fd, err, strlen(err), 0);
        }
    }
    // --- 4. FILE STORAGE & EXPLORER API ---
    else if (strcmp(clean_path, "/file/upload") == 0) {
        char filename[256], category[32], target[64];
        get_query_param(raw_path, "filename", filename, sizeof(filename));
        get_query_param(raw_path, "category", category, sizeof(category));
        get_query_param(raw_path, "target", target, sizeof(target));

        size_t content_length = parse_content_length(buffer);
        char *header_end = strstr(buffer, "\r\n\r\n");
        char *initial_body = NULL;
        size_t initial_body_len = 0;

        if (header_end) {
            initial_body = header_end + 4;
            size_t header_len = initial_body - buffer;
            if ((size_t)bytes_received > header_len) {
                initial_body_len = bytes_received - header_len;
            }
        }

        char upload_path[512];
        if (strcmp(category, "direct") == 0 && strlen(target) > 0) {
            snprintf(upload_path, sizeof(upload_path), "%s/shared_%s", target, filename);
            handle_file_upload(client_fd, "", upload_path, initial_body, initial_body_len, content_length);
        } 
        else if (strcmp(category, "group") == 0 && strlen(target) > 0) {
            snprintf(upload_path, sizeof(upload_path), "groups/%s/files/%s", target, filename);
            handle_file_upload(client_fd, "", upload_path, initial_body, initial_body_len, content_length);
        } 
        else if (strcmp(category, "global") == 0) {
            snprintf(upload_path, sizeof(upload_path), "public/%s", filename);
            handle_file_upload(client_fd, "", upload_path, initial_body, initial_body_len, content_length);
        } 
        else {
            handle_file_upload(client_fd, username, filename, initial_body, initial_body_len, content_length);
        }
    }
    else if (strcmp(clean_path, "/file/list") == 0) {
        handle_file_list(client_fd, username);
    }
    else if (strcmp(clean_path, "/file/download") == 0) {
        char filepath[256];
        get_query_param(raw_path, "filepath", filepath, sizeof(filepath));
        if (strlen(filepath) == 0) {
            get_query_param(raw_path, "filename", filepath, sizeof(filepath));
        }
        handle_file_download(client_fd, username, filepath);
    }
    // --- 5. CHAT SYSTEM: MESSAGING ---
    else if (strcmp(clean_path, "/chat/send") == 0) {
        char chat_type[16], target[64], msg[512];
        get_query_param(raw_path, "type", chat_type, sizeof(chat_type));
        get_query_param(raw_path, "target", target, sizeof(target));
        get_query_param(raw_path, "msg", msg, sizeof(msg));

        if (strlen(target) > 0 && strlen(msg) > 0) {
            char chat_file[256];
            if (strcmp(chat_type, "group") == 0) {
                snprintf(chat_file, sizeof(chat_file), "storage/groups/%s/chat.txt", target);
            } else {
                snprintf(chat_file, sizeof(chat_file), "storage/%s/inbox.txt", target);
            }

            FILE *fp = fopen(chat_file, "a");
            if (fp) {
                fprintf(fp, "[%s]: %s\n", username, msg);
                fclose(fp);

                const char *resp = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"success\",\"message\":\"Message sent!\"}";
                send(client_fd, resp, strlen(resp), 0);
            } else {
                const char *err = "HTTP/1.1 500 Internal Error\r\n\r\nFailed to open chat channel";
                send(client_fd, err, strlen(err), 0);
            }
        }
    }
    else if (strcmp(clean_path, "/chat/read") == 0) {
        char chat_type[16], target[64], chat_file[256];
        get_query_param(raw_path, "type", chat_type, sizeof(chat_type));
        get_query_param(raw_path, "target", target, sizeof(target));

        if (strcmp(chat_type, "group") == 0) {
            snprintf(chat_file, sizeof(chat_file), "storage/groups/%s/chat.txt", target);
        } else {
            snprintf(chat_file, sizeof(chat_file), "storage/%s/inbox.txt", username);
        }

        FILE *fp = fopen(chat_file, "r");
        if (fp) {
            fseek(fp, 0, SEEK_END);
            long sz = ftell(fp);
            fseek(fp, 0, SEEK_SET);
            char *content = malloc(sz + 1);
            fread(content, 1, sz, fp);
            fclose(fp);
            content[sz] = '\0';

            char header[256];
            snprintf(header, sizeof(header), "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: %ld\r\n\r\n", sz);
            send(client_fd, header, strlen(header), 0);
            send(client_fd, content, sz, 0);
            free(content);
        } else {
            const char *no_msg = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nNo messages in this chat.";
            send(client_fd, no_msg, strlen(no_msg), 0);
        }
    }
    else {
        const char *not_found = "HTTP/1.1 404 Not Found\r\n\r\nRoute not found";
        send(client_fd, not_found, strlen(not_found), 0);
    }

    close(client_fd);
}

int main() {
    ensure_storage_dirs();
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in address;
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(8080);

    bind(server_fd, (struct sockaddr *)&address, sizeof(address));
    listen(server_fd, 10);

    printf("☁️ Mini Cloud Engine online listening on port 8080...\n");

    while (1) {
        int client_fd = accept(server_fd, NULL, NULL);
        if (client_fd >= 0) {
            handle_client(client_fd);
        }
    }
    return 0;
}
