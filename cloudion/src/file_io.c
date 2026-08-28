#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>
#include <arpa/inet.h>

void handle_file_upload(int client_fd, const char *username, const char *filename, const char *initial_body, size_t initial_body_len, size_t content_length) {
    char full_path[1024];
    if (strlen(username) > 0) {
        snprintf(full_path, sizeof(full_path), "storage/%s/%s", username, filename);
    } else {
        snprintf(full_path, sizeof(full_path), "storage/%s", filename);
    }

    FILE *fp = fopen(full_path, "wb");
    if (!fp) {
        const char *err = "HTTP/1.1 500 Internal Error\r\n\r\nFailed to create file.";
        send(client_fd, err, strlen(err), 0);
        return;
    }

    size_t written = 0;
    if (initial_body_len > 0) {
        fwrite(initial_body, 1, initial_body_len, fp);
        written += initial_body_len;
    }

    char buf[8192];
    while (written < content_length) {
        size_t to_read = content_length - written;
        if (to_read > sizeof(buf)) to_read = sizeof(buf);
        ssize_t r = recv(client_fd, buf, to_read, 0);
        if (r <= 0) break;
        fwrite(buf, 1, r, fp);
        written += r;
    }

    fclose(fp);

    const char *resp = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"success\",\"message\":\"File uploaded successfully!\"}";
    send(client_fd, resp, strlen(resp), 0);
}

void handle_file_list(int client_fd, const char *username) {
    char json[16384] = "{\"status\":\"success\",\"files\":[";
    int first = 1;

    // 1. Scan Personal Storage (storage/<username>/)
    char personal_dir[1024];
    snprintf(personal_dir, sizeof(personal_dir), "storage/%s", username);
    DIR *dir = opendir(personal_dir);
    if (dir) {
        struct dirent *entry;
        while ((entry = readdir(dir)) != NULL) {
            if (entry->d_name[0] == '.') continue;
            if (strcmp(entry->d_name, "inbox.txt") == 0) continue;
            
            char item_path[2048];
            snprintf(item_path, sizeof(item_path), "%s/%s", personal_dir, entry->d_name);
            struct stat st;
            if (stat(item_path, &st) == 0 && S_ISREG(st.st_mode)) {
                if (!first) strcat(json, ",");
                first = 0;
                char file_item[2048];
                snprintf(file_item, sizeof(file_item), 
                    "{\"name\":\"%s\",\"category\":\"Personal\",\"path\":\"%s\",\"size\":%ld}",
                    entry->d_name, entry->d_name, (long)st.st_size);
                strcat(json, file_item);
            }
        }
        closedir(dir);
    }

    // 2. Scan Global/Public Storage (storage/public/)
    dir = opendir("storage/public");
    if (dir) {
        struct dirent *entry;
        while ((entry = readdir(dir)) != NULL) {
            if (entry->d_name[0] == '.') continue;
            char item_path[2048];
            snprintf(item_path, sizeof(item_path), "storage/public/%s", entry->d_name);
            struct stat st;
            if (stat(item_path, &st) == 0 && S_ISREG(st.st_mode)) {
                if (!first) strcat(json, ",");
                first = 0;
                char file_item[2048];
                snprintf(file_item, sizeof(file_item), 
                    "{\"name\":\"%s\",\"category\":\"Global Public\",\"path\":\"public/%s\",\"size\":%ld}",
                    entry->d_name, entry->d_name, (long)st.st_size);
                strcat(json, file_item);
            }
        }
        closedir(dir);
    }

    // 3. Scan Group Storage (storage/groups/<group_name>/files/)
    dir = opendir("storage/groups");
    if (dir) {
        struct dirent *grp_entry;
        while ((grp_entry = readdir(dir)) != NULL) {
            if (grp_entry->d_name[0] == '.') continue;
            char grp_files_dir[1024];
            snprintf(grp_files_dir, sizeof(grp_files_dir), "storage/groups/%s/files", grp_entry->d_name);
            DIR *gdir = opendir(grp_files_dir);
            if (gdir) {
                struct dirent *fentry;
                while ((fentry = readdir(gdir)) != NULL) {
                    if (fentry->d_name[0] == '.') continue;
                    char item_path[2048];
                    snprintf(item_path, sizeof(item_path), "%s/%s", grp_files_dir, fentry->d_name);
                    struct stat st;
                    if (stat(item_path, &st) == 0 && S_ISREG(st.st_mode)) {
                        if (!first) strcat(json, ",");
                        first = 0;
                        char file_item[2048];
                        snprintf(file_item, sizeof(file_item), 
                            "{\"name\":\"%s\",\"category\":\"Group (%s)\",\"path\":\"groups/%s/files/%s\",\"size\":%ld}",
                            fentry->d_name, grp_entry->d_name, grp_entry->d_name, fentry->d_name, (long)st.st_size);
                        strcat(json, file_item);
                    }
                }
                closedir(gdir);
            }
        }
        closedir(dir);
    }

    strcat(json, "]}");

    char header[256];
    snprintf(header, sizeof(header), "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: %zu\r\n\r\n", strlen(json));
    send(client_fd, header, strlen(header), 0);
    send(client_fd, json, strlen(json), 0);
}

void handle_file_download(int client_fd, const char *username, const char *rel_path) {
    char full_path[1024];
    if (strncmp(rel_path, "public/", 7) == 0 || strncmp(rel_path, "groups/", 7) == 0) {
        snprintf(full_path, sizeof(full_path), "storage/%s", rel_path);
    } else {
        snprintf(full_path, sizeof(full_path), "storage/%s/%s", username, rel_path);
    }

    FILE *fp = fopen(full_path, "rb");
    if (!fp) {
        const char *err = "HTTP/1.1 404 Not Found\r\n\r\nFile not found.";
        send(client_fd, err, strlen(err), 0);
        return;
    }

    fseek(fp, 0, SEEK_END);
    long sz = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    const char *fname = strrchr(rel_path, '/');
    if (fname) fname++;
    else fname = rel_path;

    char header[512];
    snprintf(header, sizeof(header), 
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: application/octet-stream\r\n"
        "Content-Disposition: attachment; filename=\"%s\"\r\n"
        "Content-Length: %ld\r\n\r\n", fname, sz);
    send(client_fd, header, strlen(header), 0);

    char buf[8192];
    size_t bytes;
    while ((bytes = fread(buf, 1, sizeof(buf), fp)) > 0) {
        send(client_fd, buf, bytes, 0);
    }

    fclose(fp);
}
