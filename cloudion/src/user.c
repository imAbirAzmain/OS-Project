/* Path: mini_cloud/src/user.c */
#include "server.h"

// Forward declaration to prevent implicit function declaration error
void get_query_param(const char *url, const char *param, char *output, size_t out_size);

// Check if username/password pair is valid in storage/users.txt
int authenticate_user(const char *username, const char *password, char *out_token) {
    FILE *f = fopen("storage/users.txt", "r");
    if (!f) return 0;

    char line[384];
    char stored_user[128], stored_pass[128], stored_token[128];
    int authenticated = 0;

    while (fgets(line, sizeof(line), f)) {
        if (sscanf(line, "%127s %127s %127s", stored_user, stored_pass, stored_token) == 3) {
            if (strcmp(stored_user, username) == 0 && strcmp(stored_pass, password) == 0) {
                if (out_token) strcpy(out_token, stored_token);
                authenticated = 1;
                break;
            }
        }
    }
    fclose(f);
    return authenticated;
}

// Endpoint: POST/GET /user/register?user=<name>&pass=<password>
void handle_register(int client_fd, const char *raw_request) {
    char username[128] = {0}, password[128] = {0};
    
    get_query_param(raw_request, "user", username, sizeof(username));
    get_query_param(raw_request, "pass", password, sizeof(password));

    if (strlen(username) == 0 || strlen(password) == 0) {
        const char *err = "HTTP/1.1 400 Bad Request\r\n\r\nMissing username or password.";
        write(client_fd, err, strlen(err));
        return;
    }

    // 1. Create personal directory: storage/<username>
    char user_dir[256];
    snprintf(user_dir, sizeof(user_dir), "storage/%s", username);
    mkdir("storage", 0755);
    mkdir(user_dir, 0755);

    // 2. Generate token
    char token[256];
    snprintf(token, sizeof(token), "token_%s_8899", username);

    // 3. Save credential to storage/users.txt (<username> <password> <token>)
    FILE *f = fopen("storage/users.txt", "a+");
    if (f) {
        fprintf(f, "%s %s %s\n", username, password, token);
        fclose(f);
    }

    // 4. Return response JSON
    char body[512];
    snprintf(body, sizeof(body), 
        "{\"status\":\"success\",\"message\":\"Account created successfully!\",\"token\":\"%s\"}", token);

    char response[1024];
    snprintf(response, sizeof(response),
        "HTTP/1.1 201 Created\r\nContent-Type: application/json\r\nContent-Length: %zu\r\n\r\n%s",
        strlen(body), body);

    write(client_fd, response, strlen(response));
}
