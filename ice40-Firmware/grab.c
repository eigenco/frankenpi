#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <linux/input.h>
#include <time.h>
#include <stdint.h>

int main(int argc, char* argv[]){
  int rcode = 0;
  int keyboard_fd = open("/dev/input/event0", O_RDONLY | O_NONBLOCK);
  if(keyboard_fd == -1) {
    printf("Failed to open keyboard.\n");
    exit(1);
  }
  printf("Getting exclusive access: ");
  rcode = ioctl(keyboard_fd, EVIOCGRAB, 1);
  printf("%s\n", (rcode == 0) ? "SUCCESS" : "FAILURE");
  printf("%d\n", EVIOCGRAB);
  rcode = ioctl(keyboard_fd, EVIOCGRAB, 0);
  close(keyboard_fd);

  return 0;
}
