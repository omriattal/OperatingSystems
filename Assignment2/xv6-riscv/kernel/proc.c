#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
int nexttid = 1;
struct spinlock pid_lock;
struct spinlock tid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);
static void freethread(struct thread *); // ADDED: freethread
extern char trampoline[];                // trampoline.S
extern void *call_start;
extern void *call_end;

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++)
    {
        char *pa = kalloc();
        if (pa == 0)
            panic("kalloc");
        uint64 va = KSTACK((int)(p - proc));
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    }
}

// initialize the proc table at boot time.
// ADDED: changed procinit to initiate the threads kstacks
void procinit(void)
{
    struct proc *p;

    initlock(&pid_lock, "nextpid");
    initlock(&wait_lock, "wait_lock");
    for (p = proc; p < &proc[NPROC]; p++)
    {
        initlock(&p->lock, "proc");
        for (int t = 0; t < NTHREADS; t++)
        {
            initlock(&p->threads[t].lock, "thread");
        }
    }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    int id = r_tp();
    return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    int id = cpuid();
    struct cpu *c = &cpus[id];
    return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    push_off();
    struct cpu *c = mycpu();
    struct proc *p = c->proc;
    pop_off();
    return p;
}

// ADDED: mythread
struct thread *
mythread(void)
{
    push_off();
    struct cpu *c = mycpu();
    struct thread *t = c->thread;
    pop_off();
    return t;
}

int allocpid()
{
    int pid;

    acquire(&pid_lock);
    pid = nextpid;
    nextpid = nextpid + 1;
    release(&pid_lock);

    return pid;
}

// ADDED: allocating thread id
int alloctid()
{
    int tid;
    acquire(&tid_lock);
    tid = nexttid;
    nexttid = nexttid + 1;
    release(&tid_lock);
    return tid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
// ADDED: overhauled the allocproc function with threads.
static struct proc *
allocproc(void)
{
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    {
        acquire(&p->lock);
        if (p->state == PUNUSED)
        {
            goto found;
        }
        else
        {
            release(&p->lock);
        }
    }
    return 0;

found:
    p->pid = allocpid();
    p->state = PUSED;

    // Create the main thread
    struct thread *t = &p->threads[MAIN_THREAD_INDEX];

    // Allocate a trapframe page that will hold all the threads trap frames an the backup trapframe.
    if ((p->trapframes = (struct trapframe *)kalloc()) == 0)
    {
        freeproc(p);
        release(&p->lock);
        return 0;
    }
    t->trapframe = p->trapframes;

    t->cid = MAIN_THREAD_INDEX;
    t->tid = alloctid();
    t->state = TUSED;

    // Allocate a trapframe_backup page.
    p->trapframe_backup = t->trapframe + NTHREADS;

    // Set up new context to start executing at forkret,
    // which returns to user space.
    memset(&t->context, 0, sizeof(t->context));
    t->context.ra = (uint64)forkret;
    if ((t->kstack = (uint64)kalloc()) == 0)
    {
        freeproc(p);
        release(&p->lock);
        return 0;
    }
    t->context.sp = t->kstack + PGSIZE;

    t->parent = p;

    // Set main thread field for comfort purposes
    p->main_thread = t;

    for (int i = 0; i < SIGNAL_SIZE; i++)
    {
        p->signal_handlers[i] = (void *)SIG_DFL;
    }

    //ignoring sigcont signal at the start
    p->signal_handlers[SIGCONT] = (void *)SIG_IGN;

    // An empty user page table.
    p->pagetable = proc_pagetable(p);
    if (p->pagetable == 0)
    {
        freeproc(p);
        release(&p->lock);
        return 0;
    }
    return p;
}

// ADDED: allocing threads
static struct thread *
allocthread(struct proc *p)
{
    int t_idx;
    struct thread *t;
    for (t_idx = 0; t_idx < NTHREADS; t_idx++)
    {
        t = &p->threads[t_idx];
        if (t == mythread())
            continue;
        acquire(&t->lock);
        if (t->state == TUNUSED)
        {
            goto found;
        }
        else
        {
            release(&t->lock);
        }
    }
    return 0;

found:
    t->cid = t_idx;
    t->tid = alloctid();
    t->state = TUSED;
    t->trapframe = p->trapframes + t_idx;
    t->parent = p;
    t->killed = 0;

    // Set up new context to start executing at forkret,
    // which returns to user space.
    memset(&t->context, 0, sizeof(t->context));
    t->context.ra = (uint64)forkret;
    if ((t->kstack = (uint64)kalloc()) == 0)
    {
        freethread(t);
        release(&t->lock);
        return 0;
    }
    t->context.sp = t->kstack + PGSIZE;
    return t;
}

// ADDED: kthread create
int kthread_create(uint64 start_func, uint64 stack)
{
    struct proc *p = myproc();
    struct thread *nt;

    acquire(&p->lock);
    if (p->exiting)
    {
        release(&p->lock);
        return -1;
    }
    release(&p->lock);

    if ((nt = allocthread(p)) == 0)
    {
        return -1;
    }

    *nt->trapframe = *mythread()->trapframe;
    nt->trapframe->epc = start_func;
    nt->trapframe->sp = stack + STACK_SIZE;

    nt->state = TRUNNABLE;
    release(&nt->lock);

    return nt->tid;
}

// ADDED: finding replacement as a mainthread
struct thread *find_replacement(struct proc *p)
{
    for (struct thread *t = p->threads; t < &proc->threads[NTHREADS]; t++)
    {
        if (t != p->main_thread)
        {
            acquire(&t->lock);
            if (t->state != TUNUSED)
            {
                release(&t->lock);
                return t;
            }
            release(&t->lock);
        }
    }
    return 0;
}

// todo: implement this function.
// ADDED: new system call!
void kthread_exit(int status)
{
    struct thread *t = mythread();
    struct proc *p = myproc();
    acquire(&p->lock);
    acquire(&t->lock);
    if (t == p->main_thread && (p->main_thread = find_replacement(p)) == 0)
    {
        p->main_thread = p->threads;
        p->state = PZOMBIE;
        release(&p->lock);
        release(&t->lock);
        exit(status);
    }

    t->xstate = status;
    t->state = TZOMBIE;
    release(&p->lock);
    wakeup(t);

    sched();
    panic("! at the disco");
}

// ADDED: a new function that frees the thread sent as an argument
static void
freethread(struct thread *t)
{
    if (t->kstack)
        kfree((void *)t->kstack);
    t->kstack = 0;
    t->trapframe = 0;
    t->tid = 0;
    t->parent = 0;
    t->chan = 0;
    t->killed = 0;
    t->state = TUNUSED;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
    // Free all threads to stay on the safe side.
    for (struct thread *t = p->threads; t < &p->threads[NTHREADS]; t++)
        freethread(t);

    // ADDED: freeing trapframe page
    if (p->trapframes)
        kfree(p->trapframes);
    p->trapframes = 0;
    p->trapframe_backup = 0;

    if (p->pagetable)
        proc_freepagetable(p->pagetable, p->sz);
    p->pagetable = 0;

    p->sz = 0;
    p->pid = 0;
    p->parent = 0;
    p->name[0] = 0;
    p->xstate = 0;
    p->exiting = 0;
    p->state = PUNUSED;
    p->killed = 0;
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
    pagetable_t pagetable;

    // An empty page table.
    pagetable = uvmcreate();
    if (pagetable == 0)
        return 0;

    // map the trampoline code (for system call return)
    // at the highest user virtual address.
    // only the supervisor uses it, on the way
    // to/from user space, so not PTE_U.
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
                 (uint64)trampoline, PTE_R | PTE_X) < 0)
    {
        uvmfree(pagetable, 0);
        return 0;
    }
    // map the trapframe just below TRAMPOLINE, for trampoline.S.
    if (mappages(pagetable, TRAPFRAME(0), PGSIZE,
                 (uint64)(p->trapframes), PTE_R | PTE_W) < 0)
    {
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
        uvmfree(pagetable, 0);
        return 0;
    }

    return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
//ADDED: support modifying the TRAPFRAME macro
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmunmap(pagetable, TRAPFRAME(MAIN_THREAD_INDEX), 1, 0);
    uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
void userinit(void)
{

    struct proc *p;

    p = allocproc();
    initproc = p;

    // allocate one user page and copy init's instructions
    // and data into it.
    uvminit(p->pagetable, initcode, sizeof(initcode));
    p->sz = PGSIZE;

    // prepare for the very first "return" from kernel to user.
    p->main_thread->trapframe->epc = 0;     // user program counter
    p->main_thread->trapframe->sp = PGSIZE; // user stack pointer

    safestrcpy(p->name, "initcode", sizeof(p->name));
    p->cwd = namei("/");

    p->main_thread->state = TRUNNABLE;
    release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
// ADDED: synchronization to growproc
int growproc(int n)
{
    uint sz;
    struct proc *p = myproc();
    
    acquire(&p->lock);
    sz = p->sz;
    if (n > 0)
    {
        if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
        {
            release(&p->lock);
            return -1;
        }
    }
    else if (n < 0)
    {
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    }
    p->sz = sz;
    release(&p->lock);
    return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.

// ADDED: overhauled the fork syscall to support thread
int fork(void)
{
    int signal, pid;
    struct proc *np;
    struct thread *t = mythread();
    struct proc *p = t->parent;

    // Allocate process (and its main thread)
    if ((np = allocproc()) == 0)
    {
        return -1;
    }

    // Copy user memory from parent to child.
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    {
        freeproc(np);
        release(&np->lock);
        return -1;
    }
    np->sz = p->sz;

    // copy saved user registers.
    *(np->main_thread->trapframe) = *(t->trapframe);

    // Cause fork to return 0 in the child.
    np->main_thread->trapframe->a0 = 0;

    // increment reference counts on open file descriptors.
    for (signal = 0; signal < NOFILE; signal++)
        if (p->ofile[signal])
            np->ofile[signal] = filedup(p->ofile[signal]);
    np->cwd = idup(p->cwd);

    safestrcpy(np->name, p->name, sizeof(p->name));

    pid = np->pid;

    release(&np->lock);

    acquire(&wait_lock);
    np->parent = p;
    np->signal_mask = p->signal_mask;
    for (int signal = 0; signal < SIGNAL_SIZE; signal++)
    {
        np->signal_handlers[signal] = p->signal_handlers[signal];
        np->signal_handlers_masks[signal] = p->signal_handlers_masks[signal];
    }

    release(&wait_lock);

    acquire(&np->main_thread->lock);
    np->main_thread->state = TRUNNABLE;
    release(&np->main_thread->lock);

    return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
    struct proc *pp;

    for (pp = proc; pp < &proc[NPROC]; pp++)
    {
        if (pp->parent == p)
        {
            pp->parent = initproc;
            wakeup(initproc);
        }
    }
}

void exit_all_other_threads()
{    
    struct proc *p = myproc();
    struct thread *t = mythread();

    for (struct thread *t_iter = p->threads; t_iter < &p->threads[NTHREADS]; t_iter++)
    {
        if (t_iter->tid == t->tid)
            continue;

        acquire(&t_iter->lock);
        t_iter->killed = 1;
        if (t_iter->state == TSLEEPING)
            t_iter->state = TRUNNABLE;
        release(&t_iter->lock);
    }
    for (struct thread *t_iter = p->threads; t_iter < &p->threads[NTHREADS]; t_iter++)
    {
        if (t_iter->tid == t->tid)
            continue;
        kthread_join(t_iter->tid, 0);
    }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
// ADDED: overhauled the exit syscall to kill all other threads of the same process
void exit(int status)
{
    struct proc *p = myproc();
    struct thread *t = mythread();

    if (p == initproc)
        panic("init exiting");
    acquire(&p->lock);
    if (!p->exiting)
    {
        p->exiting = 1;
        release(&p->lock);
    }
    else
    {
        release(&p->lock);
        kthread_exit(-2);
    }
    exit_all_other_threads();
    // Close all open files.
    for (int fd = 0; fd < NOFILE; fd++)
    {
        if (p->ofile[fd])
        {
            struct file *f = p->ofile[fd];
            fileclose(f);
            p->ofile[fd] = 0;
        }
    }
    begin_op();
    iput(p->cwd);
    end_op();
    p->cwd = 0;

    acquire(&wait_lock);

    // Give any children to init.
    reparent(p);

    // Parent might be sleeping in wait().
    wakeup(p->parent);

    acquire(&p->lock);
    p->xstate = status;
    p->state = PZOMBIE;
    release(&p->lock);
    acquire(&t->lock);
    t->xstate = status;
    t->state = TZOMBIE;
    release(&wait_lock);
    // printf("I finished the exit system call\n");
    // Jump into the scheduler, never to return.
    sched();
    panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(uint64 addr)
{
    struct proc *np;
    int havekids, pid;
    struct proc *p = myproc();

    acquire(&wait_lock);

    for (;;)
    {
        // Scan through table looking for exited children.
        havekids = 0;
        for (np = proc; np < &proc[NPROC]; np++)
        {
            if (np->parent == p)
            {
                // make sure the child isn't still in exit() or swtch().
                acquire(&np->lock);

                havekids = 1;
                if (np->state == PZOMBIE)
                {
                    // Found one.
                    pid = np->pid;
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                             sizeof(np->xstate)) < 0)
                    {
                        release(&np->lock);
                        release(&wait_lock);
                        return -1;
                    }
                    freeproc(np);
                    release(&np->lock);
                    release(&wait_lock);
                    return pid;
                }
                release(&np->lock);
            }
        }

        // No point waiting if we don't have any children.
        if (!havekids || p->killed)
        {
            release(&wait_lock);
            return -1;
        }

        // Wait for a child to exit.
        sleep(p, &wait_lock); //DOC: wait-sleep
    }
}
//TODO: complete implementation of this function
// ADDED: kthread join.
int kthread_join(int thread_id, uint64 status)
{
    struct thread *t = mythread();
    struct proc *p = myproc();
    struct thread *target = 0;
    if (thread_id <= 0)
    {
        return -1;
    }
    // printf("process %d thread %d called kthread join w/ tid %d\n",myproc()->pid, t->tid,thread_id);
    for (struct thread *t_iter = p->threads; t_iter < &p->threads[NTHREADS]; t_iter++)
    {
        if (t_iter == t)
            continue;
        acquire(&t_iter->lock);
        if (t_iter->tid == thread_id)
        {
            target = t_iter;
            break;
        }
        release(&t_iter->lock);
    }
    if (target == 0)
        return -1;
    while (!t->killed && target->tid == thread_id && target->state != TZOMBIE && target->state != TUNUSED)
    {
        sleep(target, &target->lock);
    }
    if (!t->killed)
    {
        release(&target->lock);
        return -1;
    }
    if (target->tid == thread_id && target->state == TZOMBIE)
    {
        if (status != 0 && copyout(p->pagetable, status, (char *)&target->xstate, sizeof(int)) < 0)
        {
            release(&target->lock);
            return -1;
        }
        freethread(target);
    }
    release(&target->lock);
    return 0;
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.

// ADDED: changed the scheduler run over threads and not processes
void scheduler(void)
{
    struct proc *p;
    struct thread *t;
    struct cpu *c = mycpu();
    c->thread = 0;
    for (;;)
    {
        // Avoid deadlock by ensuring that devices can interrupt.
        intr_on();
        for (p = proc; p < &proc[NPROC]; p++)
        {
            acquire(&p->lock);
            if (p->state == PUNUSED)
            {
                release(&p->lock);
                continue;
            }
            release(&p->lock);
            // TODO: check if we could lock the process here instead of down there.

            for (t = p->threads; t < &p->threads[NTHREADS]; t++)
            {
                acquire(&t->lock);
                if (t->state == TRUNNABLE)
                {
                    // if(p->pid == 3)
                    //     printf("running thread %d with cid %d\n", t->tid, t->cid);
                    // Switch to chosen thread.  It is the threads's job
                    // to release its lock and then reacquire it
                    // before jumping back to us.
                    t->state = TRUNNING;
                    c->thread = t;
                    c->proc = p;

                    swtch(&c->context, &t->context);

                    // printf("Thread %d with cid %d came back from switch with state %d\n",t->tid,t->cid, t->state);
                    // Process is done running for now.
                    // It should have changed its p->state before coming back.
                    c->thread = 0;
                    c->proc = 0;
                }
                release(&t->lock);
            }
        }
    }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
// ADDED: changed to dealin with thread instead of process
void sched(void)
{
    int intena;
    struct thread *t = mythread();
    if (!holding(&t->lock))
    {
        panic("sched t->lock");
    }
    if (mycpu()->noff != 1)
        panic("sched locks");
    if (t->state == TRUNNING)
        panic("sched running");
    if (intr_get())
        panic("sched interruptible");

    intena = mycpu()->intena;
    swtch(&t->context, &mycpu()->context);
    mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
//ADDED: changed yield with mythread
void yield(void)
{
    struct thread *t = mythread();
    acquire(&t->lock);
    t->state = TRUNNABLE;
    sched();
    release(&t->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    static int first = 1;

    // Still holding p->lock from scheduler.
    // ADDED: mythread instead of myproc
    release(&mythread()->lock);

    if (first)
    {
        // File system initialization must be run in the context of a
        // regular process (e.g., because it calls sleep), and thus cannot
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
//ADDED: changed to support threads.
void sleep(void *chan, struct spinlock *lk)
{
    struct thread *t = mythread();

    // Must acquire p->lock in order to
    // change p->state and then call sched.
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&t->lock); //DOC: sleeplock1
    release(lk);
    // Go to sleep.
    t->chan = chan;
    t->state = TSLEEPING;

    sched();

    // Tidy up.
    t->chan = 0;

    // Reacquire original lock.
    release(&t->lock);
    acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
//ADDED: waking up all threads.
void wakeup(void *chan)
{
    struct proc *p;
    struct thread *t;

    for (p = proc; p < &proc[NPROC]; p++)
    {
        acquire(&p->lock);
        for (t = p->threads; t < &p->threads[NTHREADS]; t++)
        {
            if (t != mythread())
            {
                acquire(&t->lock);
                if (t->state == TSLEEPING && t->chan == chan)
                {
                    t->state = TRUNNABLE;
                }
                release(&t->lock);
            }
        }
        release(&p->lock);
    }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
// ADDED: changed the kill system call to be like linux!
int kill(int pid, int signum)
{
    if (signum < 0 || signum >= SIGNAL_SIZE)
    {
        return -1;
    }
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++)
    {
        acquire(&p->lock);
        if (p->pid == pid)
        {
            p->pending_signals |= 1 << signum;
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    }
    return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    struct proc *p = myproc();
    if (user_dst)
    {
        return copyout(p->pagetable, dst, src, len);
    }
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    struct proc *p = myproc();
    if (user_src)
    {
        return copyin(p->pagetable, dst, src, len);
    }
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
// TODO: consider giving an f about this.
void procdump(void)
{
    static char *states[] = {
        [PUNUSED] "unused",
        [PUSED] "sleep ",
        [PZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    for (p = proc; p < &proc[NPROC]; p++)
    {
        if (p->state == PUNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
            state = states[p->state];
        else
            state = "???";
        printf("%d %s %s", p->pid, state, p->name);
        printf("\n");
    }
}

// ADDED: sigprocmask system call
uint sigprocmask(uint sigmask)
{
    struct proc *p = myproc();
    uint prev_signalmask;
    acquire(&p->lock);
    prev_signalmask = p->signal_mask;
    if ((sigmask & (1 << SIGKILL)) || (sigmask & (1 << SIGSTOP)))
    {
        release(&p->lock);
        return -1;
    }
    p->signal_mask = sigmask;
    release(&p->lock);
    return prev_signalmask;
}

// ADDED: sigaction system call
int sigaction(int signum, uint64 act, uint64 oldact)
{
    struct proc *p = myproc();
    struct sigaction new, old;
    acquire(&p->lock);
    if (signum < 0 || signum > SIGNAL_SIZE - 1 || signum == SIGKILL || signum == SIGSTOP)
    {
        release(&p->lock);
        return -1;
    }
    if (oldact != 0)
    {
        old.sa_handler = p->signal_handlers[signum];
        old.sigmask = p->signal_handlers_masks[signum];
        if (copyout(p->pagetable, oldact, (char *)&old, sizeof(struct sigaction)) < 0)
        {
            release(&p->lock);
            return -1;
        }
    }
    if (act != 0)
    {
        if (copyin(p->pagetable, (char *)&new, act, sizeof(struct sigaction)) < 0)
        {
            release(&p->lock);
            return -1;
        }
        if ((new.sigmask & 1 << SIGKILL) || (new.sigmask & 1 << SIGSTOP))
        {
            release(&p->lock);
            return -1;
        }
        p->signal_handlers[signum] = new.sa_handler;
        p->signal_handlers_masks[signum] = new.sigmask;
    }
    release(&p->lock);
    return 0;
}

// ADDED: sigret system call
void sigret(void)
{
    struct proc *p = myproc();
    struct thread *t = mythread();
    acquire(&p->lock);
    acquire(&t->lock);
    memmove(t->trapframe, p->trapframe_backup, sizeof(struct trapframe));
    p->signal_mask = p->signal_mask_backup;
    p->handling_signal = 0;
    release(&t->lock);
    release(&p->lock);
}

// ADDED: kill signal handler
void kill_handler()
{
    struct proc *p = myproc();
    p->killed = 1;
}

uint should_continue()
{
    struct proc *p = myproc();
    uint retval = 0;
    acquire(&p->lock);
    uint pending = p->pending_signals & ~(p->signal_mask);
    for (int signal = 0; signal < SIGNAL_SIZE; signal++)
    {
        if ((pending & (1 << signal)) && signal != SIGSTOP)
        {
            if (signal == SIGCONT && p->signal_handlers[SIGCONT] == (void *)SIG_DFL)
            {
                retval = 1;
                break;
            }
            else if (p->signal_handlers[signal] == (void *)SIGCONT)
            {
                retval = 1;
                break;
            }
        }
    }
    release(&p->lock);
    return retval;
}

// ADDED: stop signal handler
void stop_handler()
{
    struct proc *p = myproc();
    p->stopped = 1;
    p->signal_handlers[SIGCONT] = (void *)SIG_DFL;
    release(&p->lock);
    while (p->stopped && !should_continue())
    {
        yield();
    }
    acquire(&p->lock);
}

// ADDED: cont signal handler
void cont_handler(int signal)
{
    struct proc *p = myproc();
    p->stopped = 0;
    p->signal_handlers[signal] = (void *)SIG_IGN;
}

// ADDED: handle kernel signals
void handle_kernel_signals()
{
    struct proc *p = myproc();
    acquire(&p->lock);
    uint pending = p->pending_signals & ~(p->signal_mask);
    for (int signal = 0; signal < SIGNAL_SIZE; signal++)
    {
        if (pending & (1 << signal))
        {

            void *handler = p->signal_handlers[signal];
            if ((handler == (void *)SIG_DFL && signal == SIGSTOP) || handler == (void *)SIGSTOP)
            {
                p->pending_signals &= ~(1 << signal);
                printf("dispatching stop handler\n");
                stop_handler();
            }
            else if ((handler == (void *)SIG_DFL && signal == SIGCONT) || handler == (void *)SIGCONT)
            {
                p->pending_signals &= ~(1 << signal);
                printf("dispatching cont handler\n");
                cont_handler(signal);
            }
            else if ((handler == (void *)SIG_DFL) || (handler == (void *)SIGKILL))
            {
                p->pending_signals &= ~(1 << signal);
                // printf("dispatching kill handler\n");
                kill_handler();
                release(&p->lock);
                return;
            }
            else if (handler == (void *)SIG_IGN)
            {
                p->pending_signals &= ~(1 << signal);
                printf("ignoring signals\n");
            }
        }
    }
    release(&p->lock);
}

// ADDED: handle user signals
void handle_user_signals()
{
    struct proc *p = myproc();
    struct thread *t = mythread();
    uint64 call_size;
    acquire(&p->lock);
    acquire(&t->lock);
    uint pending = p->pending_signals & ~(p->signal_mask);
    for (int signal = 0; signal < SIGNAL_SIZE; signal++)
    {
        if (pending & (1 << signal))
        {
            p->handling_signal = 1;
            p->pending_signals &= ~(1 << signal);
            void *handler = p->signal_handlers[signal];
            memmove(p->trapframe_backup, t->trapframe, sizeof(struct trapframe));
            p->signal_mask_backup = p->signal_mask;
            p->signal_mask = p->signal_handlers_masks[signal];
            call_size = (uint64)&call_end - (uint64)&call_start;
            t->trapframe->sp -= call_size;
            copyout(p->pagetable, (uint64)(t->trapframe->sp), (char *)&call_start, call_size);
            t->trapframe->a0 = signal;
            t->trapframe->ra = t->trapframe->sp;
            t->trapframe->epc = (uint64)handler;
            break;
        }
    }
    release(&t->lock);
    release(&p->lock);
}

int kthread_id() { return mythread()->tid; }
