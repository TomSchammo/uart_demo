#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

int main(int argc, char **argv) {

  if (argc != 2) {
    puts("invalid number of command line arguments, expected a device path");
    return EXIT_FAILURE;
  }

  const char *device = argv[1];

  int fd = open(device, O_RDONLY | O_NOCTTY);
  if (fd < 0) {
    int e = errno;
    fprintf(stderr, "open %s: %s\n", device, strerror(e));
    return EXIT_FAILURE;
  }

  struct termios tty;
  if (tcgetattr(fd, &tty) != 0) {
    perror("tcgetattr");
    close(fd);
    return EXIT_FAILURE;
  }

  cfmakeraw(&tty);
  cfsetispeed(&tty, B115200);
  cfsetospeed(&tty, B115200);

  // 8N1, ignore modem control lines
  tty.c_cflag &= ~(PARENB | CSTOPB | CSIZE);
  tty.c_cflag |= CS8 | CREAD | CLOCAL;

  // block until at least one byte is available
  tty.c_cc[VMIN] = 1;
  tty.c_cc[VTIME] = 0;

  if (tcsetattr(fd, TCSANOW, &tty) != 0) {
    perror("tcsetattr");
    close(fd);
    return EXIT_FAILURE;
  }

  tcflush(fd, TCIFLUSH);

  // the FPGA sends each 16 bit counter value as two frames, low byte first
  uint8_t buf[2];
  size_t have = 0;

  for (;;) {
    ssize_t n = read(fd, buf + have, sizeof(buf) - have);
    if (n < 0) {
      perror("read");
      close(fd);
      return EXIT_FAILURE;
    }
    if (n == 0)
      continue;

    have += (size_t)n;
    if (have == sizeof(buf)) {
      uint16_t value = (uint16_t)(buf[0] | (buf[1] << 8));
      printf("%u\n", value);
      have = 0;
    }
  }

  close(fd);
  return EXIT_SUCCESS;
}
