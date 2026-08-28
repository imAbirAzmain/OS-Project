/* Path: mini_cloud/src/social.c */
#include "server.h"

// Helper to extract query parameters like ?user=alice&friend=bob
static void get_param(const char *url, const char *key, char *output, size_t max_len) {
    char search_key[64];
    snprintf(search_key, sizeof(search_key), "%s=", key);
    
    char *start = strstr(url, search_key);
    if (!start) {
        output[0] = '\0';
        return;
    }
    start += strlen(search_key);
    
    size_t i = 0;
    while (start[i] != '\0' && start[i] != '&' && start[i] != ' ' && i < max_len - 1) {
        output[i] = start[i];
        i++;
    }
    output[i] = '\0';
}

void handle_social_request(int client_fd, http_request_t *req, const char *raw_request) {
    // --- 1. ADD FRIEND ENDPOINT ---
    if (strstr(req->path, "/social/add_friend") == req->path) {
        char user[64] = {0}, friend_name[64] = {0};
        get_param(req->path, "user", user, sizeof(user));
        get_param(req->path, "friend", friend_name, sizeof(friend_name));

        if (strlen(user) == 0 || strlen(friend_name) == 0) {
            const char *resp = "HTTP/1.1 400 Bad Request\r\n\r\n[!] Missing user or friend parameter.";
            write(client_fd, resp, strlen(resp));
            return;
        }

        char friends_path[512];
        snprintf(friends_path, sizeof(friends_path), "storage/%s/friends.txt", user);

        // Open in Append Mode with 0600 security permissions
        int fd = open(friends_path, O_WRONLY | O_CREAT | O_APPEND, 0600);
        if (fd < 0) {
            const char *resp = "HTTP/1.1 500 Internal Error\r\n\r\n[!] Could not access friend storage.";
            write(client_fd, resp, strlen(resp));
            return;
        }

        dprintf(fd, "%s\n", friend_name);
        close(fd);

        const char *resp = "HTTP/1.1 200 OK\r\n\r\n[✔] Friend added successfully!\n";
        write(client_fd, resp, strlen(resp));
        return;
    }

    // --- 2. SEND MESSAGE ENDPOINT ---
    if (strstr(req->path, "/social/send") == req->path) {
        char from[64] = {0}, to[64] = {0};
        get_param(req->path, "from", from, sizeof(from));
        get_param(req->path, "to", to, sizeof(to));

        // Locate HTTP body for the message content
        const char *body = strstr(raw_request, "\r\n\r\n");
        if (!body || strlen(from) == 0 || strlen(to) == 0) {
            const char *resp = "HTTP/1.1 400 Bad Request\r\n\r\n[!] Invalid parameters or missing body.";
            write(client_fd, resp, strlen(resp));
            return;
        }
        body += 4; // Skip CRLF CRLF

        char inbox_path[512];
        snprintf(inbox_path, sizeof(inbox_path), "storage/%s/inbox.txt", to);

        int fd = open(inbox_path, O_WRONLY | O_CREAT | O_APPEND, 0600);
        if (fd < 0) {
            const char *resp = "HTTP/1.1 404 Not Found\r\n\r\n[!] Recipient user inbox does not exist.";
            write(client_fd, resp, strlen(resp));
            return;
        }

        dprintf(fd, "From: %s\nMessage: %s\n---\n", from, body);
        close(fd);

        const char *resp = "HTTP/1.1 200 OK\r\n\r\n[✔] Message sent successfully!\n";
        write(client_fd, resp, strlen(resp));
        return;
    }

    // --- 3. READ INBOX ENDPOINT ---
    if (strstr(req->path, "/social/inbox") == req->path) {
        char user[64] = {0};
        get_param(req->path, "user", user, sizeof(user));

        if (strlen(user) == 0) {
            const char *resp = "HTTP/1.1 400 Bad Request\r\n\r\n[!] Missing user parameter.";
            write(client_fd, resp, strlen(resp));
            return;
        }

        char inbox_path[512];
        snprintf(inbox_path, sizeof(inbox_path), "storage/%s/inbox.txt", user);

        // Stream the inbox using handle_file_download routing logic
        handle_file_download(client_fd, inbox_path + 7); // strip "storage" prefix
        return;
    }

    const char *resp = "HTTP/1.1 404 Not Found\r\n\r\n[!] Unknown Social Route.";
    write(client_fd, resp, strlen(resp));
}
