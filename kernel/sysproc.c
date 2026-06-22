#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "vm.h"

extern struct proc proc[];

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  kexit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return kfork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return kwait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
  argint(1, &t);
  addr = myproc()->sz;

  if (t == SBRK_EAGER || n < 0) {
    if (growproc(n) < 0) {
      return -1;
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if (addr + n < addr)
      return -1;
    if (addr + n > TRAPFRAME)
      return -1;
    myproc()->sz += n;
  }
  return addr;
}

uint64
sys_pause(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  if (n < 0)
    n = 0;
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n) {
    if (killed(myproc())) {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kkill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

// getsleepinfo(int who, struct sleepinfo *buf)
//   who == 0  : current process  -> write one sleepinfo
//   who >  0  : process with pid == who -> write one sleepinfo, or -1 if not found
//   who == -1 : all processes -> write NPROC sleepinfo entries (UNUSED slots have pid=0)
uint64
sys_getsleepinfo(void)
{
  int who;
  uint64 addr;
  argint(0, &who);
  argaddr(1, &addr);

  struct proc *p = myproc();

  if (who == -1) {
    struct sleepinfo buf[NPROC];
    for (int i = 0; i < NPROC; i++) {
      struct proc *pp = &proc[i];
      acquire(&pp->lock);
      buf[i].pid         = (pp->state != UNUSED) ? pp->pid : 0;
      buf[i].sleep_ticks = pp->sleep_ticks;
      buf[i].sleep_count = pp->sleep_count;
      release(&pp->lock);
    }
    if (copyout(p->pagetable, addr, (char *)buf, sizeof(buf)) < 0)
      return -1;
    return 0;
  }

  struct proc *target = 0;
  if (who == 0) {
    target = p;
  } else {
    for (struct proc *pp = proc; pp < &proc[NPROC]; pp++) {
      acquire(&pp->lock);
      if (pp->state != UNUSED && pp->pid == who) {
        target = pp;
        release(&pp->lock);
        break;
      }
      release(&pp->lock);
    }
    if (target == 0)
      return -1;
  }

  struct sleepinfo si;
  acquire(&target->lock);
  si.pid         = target->pid;
  si.sleep_ticks = target->sleep_ticks;
  si.sleep_count = target->sleep_count;
  release(&target->lock);

  if (copyout(p->pagetable, addr, (char *)&si, sizeof(si)) < 0)
    return -1;
  return 0;
}
