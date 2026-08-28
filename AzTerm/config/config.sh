#!/bin/bash

############################################################
# AzTerm Configuration
############################################################

AZTERM_NAME="AzTerm"
AZTERM_VERSION="2.0"
AZTERM_PROMPT="az> "
AZTERM_TITLE="AzTerm v2"

# Dark terminal theme palette
COLOR_RESET=$'\033[0m'
COLOR_BLACK=$'\033[30m'
COLOR_WHITE=$'\033[37m'
COLOR_YELLOW=$'\033[1;33m'
COLOR_ORANGE=$'\033[38;5;214m'
COLOR_RED=$'\033[1;31m'
COLOR_DIM=$'\033[2;37m'
COLOR_BG_DARK=$'\033[48;5;16m'
COLOR_SUCCESS=$'\033[38;5;214m'

HISTORY_FILE="data/history.txt"

SCRIPT_DIRECTORY="scripts"

# Cloudion management settings
CLOUDION_PATH="${SCRIPT_DIR%/*}/cloudion"
CLOUDION_EXECUTABLE="bin/minicloud-server"
CLOUDION_PORT="8080"
CLOUDION_PID_FILE="${SCRIPT_DIR}/data/cloudion.pid"
CLOUDION_LOG_FILE="${SCRIPT_DIR%/*}/cloudion/logs/server.log"

