# Path: mini_cloud/Makefile
CC = gcc
CFLAGS = -Wall -Wextra -Iinclude
SRCS = src/main.c src/http.c src/file_io.c src/social.c src/user.c
OBJS = $(SRCS:.c=.o)
TARGET = bin/minicloud-server

all: $(TARGET)

$(TARGET): $(SRCS)
	@mkdir -p bin storage web
	$(CC) $(CFLAGS) $(SRCS) -o $(TARGET)

clean:
	rm -rf bin/*.o $(TARGET)
