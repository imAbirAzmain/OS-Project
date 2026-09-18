// Mirrors scripts/lib/common.sh's exit code contract (README.md section 26).
const EXIT_TO_HTTP = {
  0: 200, // SUCCESS
  1: 500, // GENERAL_ERROR
  2: 400, // INVALID_ARGUMENT
  3: 404, // FILE_NOT_FOUND
  4: 403, // PERMISSION_DENIED
  5: 507, // STORAGE_ERROR (Insufficient Storage)
  6: 400, // INVALID_PATH
  7: 403, // AUTHORIZATION_FAILURE
};

function httpStatusForExitCode(code) {
  return EXIT_TO_HTTP[code] ?? 500;
}

module.exports = { httpStatusForExitCode };
