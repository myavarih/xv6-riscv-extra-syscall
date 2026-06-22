#include "kernel/types.h"
#include "kernel/param.h"
#include "user/user.h"

static void
show_one(const char *label, struct sleepinfo *si)
{
  printf("%s: pid=%d  sleep_ticks=%lu  sleep_count=%lu\n",
         label, si->pid, si->sleep_ticks, si->sleep_count);
}

int
main(void)
{
  struct sleepinfo si;
  struct sleepinfo all[NPROC];

  // query current process before sleeping
  if (getsleepinfo(0, &si) < 0) {
    fprintf(2, "getsleepinfo: failed\n");
    exit(1);
  }
  show_one("self (before sleep)", &si);

  // sleep 5 ticks so sleep_ticks and sleep_count increment
  pause(5);

  if (getsleepinfo(0, &si) < 0) {
    fprintf(2, "getsleepinfo: failed\n");
    exit(1);
  }
  show_one("self (after  sleep)", &si);

  // query by explicit pid
  int my_pid = getpid();
  if (getsleepinfo(my_pid, &si) < 0) {
    fprintf(2, "getsleepinfo by pid: failed\n");
    exit(1);
  }
  show_one("self (by pid)       ", &si);

  // query non-existent pid — should return -1
  if (getsleepinfo(99999, &si) == 0) {
    fprintf(2, "getsleepinfo(99999): expected error, got success\n");
    exit(1);
  }
  printf("getsleepinfo(99999): correctly returned -1\n");

  // query all processes
  if (getsleepinfo(-1, all) < 0) {
    fprintf(2, "getsleepinfo(-1): failed\n");
    exit(1);
  }
  printf("\nall processes:\n");
  for (int i = 0; i < NPROC; i++) {
    if (all[i].pid == 0)
      continue;
    printf("  pid=%d  sleep_ticks=%lu  sleep_count=%lu\n",
           all[i].pid, all[i].sleep_ticks, all[i].sleep_count);
  }

  exit(0);
}
