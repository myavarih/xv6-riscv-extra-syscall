# `getsleepinfo` System Call

## Overview

`getsleepinfo` returns sleep statistics for one process or all processes: total timer ticks spent in the SLEEPING state and the number of times `sleep()` was called.

## Signature

```c
int getsleepinfo(int who, struct sleepinfo *buf);
```

### Arguments

| `who` | Meaning |
|-------|---------|
| `0`   | Current process — write one `sleepinfo` into `buf` |
| `> 0` | Process with PID == `who` — write one `sleepinfo` into `buf` |
| `-1`  | All processes — write `NPROC` `sleepinfo` entries into `buf` |

### Return value

Returns `0` on success, `-1` on error (invalid `buf` address, or `who > 0` and no matching live process).

### Struct

```c
struct sleepinfo {
    int    pid;          /* process PID (0 for unused proc-table slots) */
    uint64 sleep_ticks;  /* total timer ticks spent in SLEEPING state   */
    uint64 sleep_count;  /* number of times sleep() was called          */
};
```

## Usage examples

```c
#include "kernel/types.h"
#include "kernel/param.h"
#include "user/user.h"

/* current process */
struct sleepinfo si;
getsleepinfo(0, &si);

/* specific pid */
getsleepinfo(pid, &si);

/* all processes */
struct sleepinfo all[NPROC];
getsleepinfo(-1, all);
for (int i = 0; i < NPROC; i++)
    if (all[i].pid != 0)
        printf("pid %d: ticks=%lu count=%lu\n",
               all[i].pid, all[i].sleep_ticks, all[i].sleep_count);
```

## Implementation

### Kernel changes

**`kernel/proc.h`**
- Added `struct sleepinfo` (pid, sleep\_ticks, sleep\_count).
- Added `sleep_ticks` and `sleep_count` fields to `struct proc`.

**`kernel/proc.c` — `sleep()`**

```c
p->sleep_count++;
p->chan = chan;
p->state = SLEEPING;

uint sleep_start = ticks;   /* unsynchronized best-effort read */
sched();
p->sleep_ticks += ticks - sleep_start;
```

`ticks` is read without `tickslock` — the same best-effort approach used elsewhere in xv6 for per-process statistics. The delta is accumulated immediately after `sched()` returns (i.e., after the process wakes up).

**`kernel/syscall.h`**

```c
#define SYS_getsleepinfo 22
```

**`kernel/sysproc.c` — `sys_getsleepinfo()`**

- `who == -1`: iterates the full `proc[]` table, locks each entry, copies stats into a stack-allocated `struct sleepinfo[NPROC]`, then `copyout`s to user space.
- `who == 0`: uses `myproc()` directly.
- `who > 0`: linear scan of `proc[]` for matching PID.

### User-space changes

| File | Change |
|------|--------|
| `user/user.h` | Added `struct sleepinfo`, added `getsleepinfo` prototype |
| `user/usys.pl` | Added `entry("getsleepinfo")` |
| `user/sleepinfo.c` | Test program (see below) |
| `Makefile` | Added `$U/_sleepinfo` to `UPROGS` |

## Test program (`sleepinfo`)

Run inside xv6:

```
$ sleepinfo
```

Expected output (values vary by system load):

```
self (before sleep): pid=3  sleep_ticks=2   sleep_count=1
self (after  sleep): pid=3  sleep_ticks=7   sleep_count=2
self (by pid)       : pid=3  sleep_ticks=7   sleep_count=2
getsleepinfo(99999): correctly returned -1

all processes:
  pid=1  sleep_ticks=...  sleep_count=...
  pid=2  sleep_ticks=...  sleep_count=...
  pid=3  sleep_ticks=...  sleep_count=...
```

The program verifies:
1. `sleep_ticks` and `sleep_count` increment after `pause(5)`.
2. Querying by explicit PID returns the same data.
3. A non-existent PID returns `-1`.
4. The all-processes query lists every live process.

## Notes

- `sleep_ticks` counts timer ticks (≈ 100 ms each in the default xv6 QEMU configuration).
- Statistics are per-process and reset to zero when a process slot is reused (proc table entry is zeroed in `freeproc`).
- Reading `ticks` without `tickslock` is intentional: acquiring it inside `sleep()` while `p->lock` is held would require all callers that hold `tickslock` and then call `sleep()` (e.g., `sys_pause`) to be audited for lock ordering. The unsynchronized read gives best-effort accuracy consistent with the rest of xv6's stat counters.
