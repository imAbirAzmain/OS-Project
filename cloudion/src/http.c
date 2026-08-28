/* Path: mini_cloud/src/http.c */
#include "server.h"

void parse_http_request(const char *raw_request, http_request_t *req) {
    memset(req, 0, sizeof(http_request_t));
    
    // 1. Extract Method and Path
    sscanf(raw_request, "%15s %255s", req->method, req->path);

    // 2. Extract Content-Length header if present
    const char *cl_ptr = strstr(raw_request, "Content-Length:");
    if (cl_ptr != NULL) {
        req->content_length = atol(cl_ptr + 15);
    }

    // 3. Extract Authorization: Bearer <token> header
    const char *auth_ptr = strstr(raw_request, "Authorization: Bearer ");
    if (auth_ptr != NULL) {
        sscanf(auth_ptr + 22, "%127s", req->auth_token);
    }
}
