#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

#define next_ram_idx(i) (i + 1) % MAX_PSYC_PAGES

#if SELECTION == LAPA
#define INIT_AGE_VALUE 0xFFFFFFFF
#elif SELECTION == NFUA
#define INIT_AGE_VALUE 1 << 31 // TODO: consider
#else
#define INIT_AGE_VALUE 0
#endif

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

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
void procinit(void)
{
    struct proc *p;

    initlock(&pid_lock, "nextpid");
    initlock(&wait_lock, "wait_lock");
    for (p = proc; p < &proc[NPROC]; p++)
    {
        initlock(&p->lock, "proc");
        p->kstack = KSTACK((int)(p - proc));
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

int allocpid()
{
    int pid;

    acquire(&pid_lock);
    pid = nextpid;
    nextpid = nextpid + 1;
    release(&pid_lock);

    return pid;
}

int init_size_swap_file(struct proc *p)
{
    int max_swap_file_size = PGSIZE * MAX_SWAP_PAGES;
    char *mem = kalloc();
    for (int location = 0; location < max_swap_file_size; location += PGSIZE)
    {
        if (writeToSwapFile(p, mem, location, PGSIZE) < 0)
        {
            return -1;
        }
    }
    kfree(mem);
    return 0;
}
// ADDED: initialize the meta data
int initmetadata(struct proc *p)
{
    if (p->swapFile == NO_FILE && createSwapFile(p) < 0)
        return -1;
    for (int i = 0; i < MAX_PSYC_PAGES; i++)
    {
        p->ram_pages[i].age = 0;
        p->ram_pages[i].va = 0;
        p->ram_pages[i].state = PG_FREE;
        p->swap_pages[i].swap_location = i * PGSIZE;
        p->swap_pages[i].va = 0;
        p->swap_pages[i].state = PG_FREE;
    }
    return 0;
}

void freemetadata(struct proc *p)
{
    if (removeSwapFile(p) < 0)
        panic("freemetadata: removing swap failed");
    p->swapFile = NO_FILE;

    for (int i = 0; i < MAX_PSYC_PAGES; i++)
    {
        p->ram_pages[i].age = 0;
        p->ram_pages[i].va = 0;
        p->ram_pages[i].state = PG_FREE;
        p->swap_pages[i].va = 0;
        p->swap_pages[i].state = PG_FREE;
    }
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc *
allocproc(void)
{
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    {
        acquire(&p->lock);
        if (p->state == UNUSED)
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
    p->state = USED;
    // ADDED: statistics, metadata
    p->scfifo_out_index = 0;
    p->pagefaults = 0;
    // Allocate a trapframe page.
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    {
        freeproc(p);
        release(&p->lock);
        return 0;
    }

    // An empty user page table.
    p->pagetable = proc_pagetable(p);
    if (p->pagetable == 0)
    {
        freeproc(p);
        release(&p->lock);
        return 0;
    }
    // printf("hello there\n");

    // Set up new context to start executing at forkret,
    // which returns to user space.
    memset(&p->context, 0, sizeof(p->context));
    p->context.ra = (uint64)forkret;
    p->context.sp = p->kstack + PGSIZE;

    return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
    if (p->trapframe)
        kfree((void *)p->trapframe);
    p->trapframe = 0;
    if (p->pagetable)
        proc_freepagetable(p->pagetable, p->sz);
    p->pagetable = 0;
    p->sz = 0;
    p->pid = 0;
    p->parent = 0;
    p->name[0] = 0;
    p->chan = 0;
    p->killed = 0;
    p->xstate = 0;
    p->state = UNUSED;
    // ADDED: delete staticstics and metadata
    p->scfifo_out_index = 0;
    p->pagefaults = 0;
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
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
                 (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
    {
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
        uvmfree(pagetable, 0);
        return 0;
    }

    return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
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
    p->trapframe->epc = 0;     // user program counter
    p->trapframe->sp = PGSIZE; // user stack pointer

    safestrcpy(p->name, "initcode", sizeof(p->name));
    p->cwd = namei("/");

    p->state = RUNNABLE;

    release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
    uint sz;
    struct proc *p = myproc();

    sz = p->sz;
    if (n > 0)
    {
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, 1)) == 0)
        {
            return -1;
        }
    }
    else if (n < 0)
    {
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    }
    p->sz = sz;
    return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{
    int i, pid;
    struct proc *np;
    struct proc *p = myproc();

    // Allocate process.
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
    // ADDED: copy the scfifo index
    np->scfifo_out_index = p->scfifo_out_index;
    // copy saved user registers.
    *(np->trapframe) = *(p->trapframe);

    // Cause fork to return 0 in the child.
    np->trapframe->a0 = 0;

    // increment reference counts on open file descriptors.
    for (i = 0; i < NOFILE; i++)
        if (p->ofile[i])
            np->ofile[i] = filedup(p->ofile[i]);
    np->cwd = idup(p->cwd);

    safestrcpy(np->name, p->name, sizeof(p->name));

    pid = np->pid;
    release(&np->lock);

    acquire(&wait_lock);
    np->parent = p;

    release(&wait_lock);

    if (isSwapProc(np))
    {
        // ADDED: initializing ram and swap pages.
        if (initmetadata(np) < 0)
        {
            printf("fork: failed initmetadata\n");
            freeproc(np);
            return -1;
        }
        if (init_size_swap_file(np) < 0)
        {
            printf("fork: failed init size swap file\n");
            freeproc(np);
            return -1;
        }
        if (!isSwapProc(p))
        {
            int max_swap_file_size = PGSIZE * MAX_SWAP_PAGES;
            char *mem = kalloc();
            for (int location = 0; location < max_swap_file_size; location += PGSIZE)
            {
                if (writeToSwapFile(np, mem, location, PGSIZE) < 0)
                {
                    freeproc(np);
                    release(&np->lock);
                    return -1;
                }
            }
            kfree(mem);
        }
    }

    if (isSwapProc(p))
    {
        // ADDED: copying swap and metadata for ram and swap pages.
        if (copySwapFile(np, p) < 0)
        {
            printf("fork: failed copying swapfile\n");
            freeproc(np);
            return -1;
        }
        // ADDED: copy the ram and swap pages array from the parent process.
        memmove(np->ram_pages, p->ram_pages, sizeof(p->ram_pages));
        memmove(np->swap_pages, p->swap_pages, sizeof(p->swap_pages));
    }

    acquire(&np->lock);
    np->state = RUNNABLE;
    release(&np->lock);
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

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
    struct proc *p = myproc();

    if (p == initproc)
        panic("init exiting");

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
    // ADDED: deleting the metadata of the process
    if (isSwapProc(p))
        freemetadata(p);

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
    p->state = ZOMBIE;

    release(&wait_lock);

    // Jump into the , never to return.
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
                if (np->state == ZOMBIE)
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
                    // ADDED: freeing the swap and metadata of np.
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
// ADDED: update the ages per process.
void update_ages(struct proc *p)
{
    p->counter++;
    int index = 0;
    for (struct ram_page *rmpg = p->ram_pages; rmpg < &p->ram_pages[MAX_PSYC_PAGES]; rmpg++)
    {
        pte_t *pte = walk(p->pagetable, rmpg->va, 0);
        rmpg->age >>= 1; // shift right
        if (*pte & PTE_A)
        {
            rmpg->age |= (1 << 31); // adding 1 to the MSB of age.
            // printf("ram page %d with age %p\n", index, rmpg->age);
            *pte &= ~PTE_A;
        }
        index++;
    }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void scheduler(void)
{
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    for (;;)
    {
        // Avoid deadlock by ensuring that devices can interrupt.
        intr_on();

        for (p = proc; p < &proc[NPROC]; p++)
        {
            acquire(&p->lock);
            if (p->state == RUNNABLE)
            {
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
// ADDED: update ages array of the process
#if SELECTION == NFUA || SELECTION == LAPA
                update_ages(p);
#endif
                // Process is done running for now.
                // It should have changed its p->state before coming back.
                c->proc = 0;
            }
            release(&p->lock);
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
void sched(void)
{
    int intena;
    struct proc *p = myproc();

    if (!holding(&p->lock))
        panic("sched p->lock");
    if (mycpu()->noff != 1)
        panic("sched locks");
    if (p->state == RUNNING)
        panic("sched running");
    if (intr_get())
        panic("sched interruptible");

    intena = mycpu()->intena;
    swtch(&p->context, &mycpu()->context);
    mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
    struct proc *p = myproc();
    acquire(&p->lock);
    p->state = RUNNABLE;
    sched();
    release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
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
void sleep(void *chan, struct spinlock *lk)
{
    struct proc *p = myproc();

    // Must acquire p->lock in order to
    // change p->state and then call sched.
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); //DOC: sleeplock1
    release(lk);

    // Go to sleep.
    p->chan = chan;
    p->state = SLEEPING;

    sched();

    // Tidy up.
    p->chan = 0;

    // Reacquire original lock.
    release(&p->lock);
    acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
            {
                p->state = RUNNABLE;
            }
            release(&p->lock);
        }
    }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    {
        acquire(&p->lock);
        if (p->pid == pid)
        {
            p->killed = 1;
            if (p->state == SLEEPING)
            {
                // Wake process from sleep().
                p->state = RUNNABLE;
            }
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
void procdump(void)
{
    static char *states[] = {
        [UNUSED] "unused",
        [SLEEPING] "sleep ",
        [RUNNABLE] "runble",
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    for (p = proc; p < &proc[NPROC]; p++)
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
            state = states[p->state];
        else
            state = "???";
        printf("%d %s %s", p->pid, state, p->name);
        printf("\n");
    }
}

int find_page_in_swap(struct proc *p, int va)
{
    for (int i = 0; i < MAX_PSYC_PAGES; i++)
    {
        if (p->swap_pages[i].va == va)
        {
            return i;
        }
    }
    return -1;
}

int find_free_page_in_swap(struct proc *p)
{
    for (int i = 0; i < MAX_PSYC_PAGES; i++)
    {
        if (p->swap_pages[i].state == PG_FREE)
        {
            return i;
        }
    }
    return -1;
}

int find_free_page_in_ram(struct proc *p)
{
    for (int i = 0; i < MAX_PSYC_PAGES; i++)
    {
        if (p->ram_pages[i].state == PG_FREE)
        {
            return i;
        }
    }
    return -1;
}

// TODO: support statistics
// ADDED: writing the page specified by pagenum to swapfile.
int swapout(struct proc *p, int pagenum)
{
    // printf("process %d here with pagenum %d\n",p->pid,pagenum);
    if (pagenum < 0 || pagenum > MAX_PSYC_PAGES)
        panic("swapin: pagenum sucks");

    struct ram_page *rmpg = &p->ram_pages[pagenum]; // get the page in the array
    if (rmpg->state == PG_FREE)
        panic("swapout: page free");

    pte_t *pte = walk(p->pagetable, rmpg->va, 0); // get the PTE of the chosen pagef
    if (pte == 0)
        panic("swapout: unallocated pte");

    // page should be valid when we swap out, if not, panic
    if (!(*pte & PTE_V) && !(*pte & PTE_LZ))
        panic("swapout: invalid page");

    struct swap_page *swpg;
    int free_swp_idx = find_free_page_in_swap(p);
    if (free_swp_idx < 0)
        return -1;

    swpg = &p->swap_pages[free_swp_idx];

    if (!(*pte & PTE_LZ))
    {
        uint64 pa = PTE2PA(*pte);
        if (writeToSwapFile(p, (char *)pa, swpg->swap_location, PGSIZE) < 0)
            return -1;    
        kfree((void *)pa);
    }

    swpg->state = PG_TAKEN;
    swpg->va = rmpg->va;
    rmpg->state = PG_FREE;
    rmpg->va = 0;
    rmpg->age = 0;
    *pte |= PTE_PG; // set the flag stating the page was swapped out
    *pte &= ~PTE_V; // clear the flag stating the page is valid
    sfence_vma();   // refreshing the TLB
    return 0;
}

// ADDED: reading page specified by pagenum from swapfile.
int swapin(struct proc *p, int swap_targetidx, int ram_freeidx)
{
    struct swap_page *swpg;

    if (ram_freeidx < 0 || ram_freeidx > MAX_PSYC_PAGES)
        panic("swapin: ram index sucks");
    if (swap_targetidx < 0 || swap_targetidx > MAX_PSYC_PAGES)
        panic("swapin: swap index sucks");

    swpg = &p->swap_pages[swap_targetidx]; // get the page in the array
    if (swpg->state == PG_FREE)
        panic("swapin: page free");
    pte_t *pte = walk(p->pagetable, swpg->va, 0);
    if (pte == 0)
        panic("swapin: unallocated pte");

    // page should be invalid and paged out when we swap in, if not, panic
    if (*pte & PTE_V || !(*pte & PTE_PG))
        panic("swapin: valid page");

    struct ram_page *rmpg = &p->ram_pages[ram_freeidx];
    if (rmpg->state == PG_TAKEN)
        panic("swapin: ram page taken");
    if (!(*pte & PTE_LZ))
    {
        uint64 new_pa = (uint64)kalloc(); //Allocating a new physical address for the swapped in page.
        if (readFromSwapFile(p, (char *)new_pa, swpg->swap_location, PGSIZE) < 0)
        {
            kfree((void *)new_pa);
            return -1;
        }
        *pte = PA2PTE(new_pa) | PTE_FLAGS(*pte); // insert the new allocated pa to the pte in the correct part
        *pte |= PTE_V;                           // set the flag stating the page is valid
    }
    rmpg->state = PG_TAKEN;
    rmpg->va = swpg->va;
    rmpg->age = INIT_AGE_VALUE;
    swpg->state = PG_FREE;
    swpg->va = 0;
    *pte &= ~PTE_PG;                         // clear the flag stating the page was swapped out
    sfence_vma();                            // refreshing the TLB
    return 0;
}

void swapin_addr(struct proc *p, uint64 pa, uint64 va, int ram_freeidx)
{
    pte_t *pte = walk(p->pagetable, va, 0);
    if (pte == 0)
        panic("swapin: unallocated pte");

    // page should be valid when we swap out, if not, panic
    if (*pte & PTE_V || !(*pte & PTE_PG))
        panic("swapin: valid page");

    struct ram_page *rmpg = &p->ram_pages[ram_freeidx];
    if (rmpg->state == PG_TAKEN)
        panic("swapin: ram page taken");

    rmpg->state = PG_TAKEN;
    rmpg->va = va;
    rmpg->age = INIT_AGE_VALUE;                 // TODO: consider
    *pte &= ~PTE_PG;                     // clear the flag stating the page was swapped out
    *pte |= PTE_V;                       // set the flag stating the page is valid
    *pte = PA2PTE(pa) | PTE_FLAGS(*pte); // insert the new allocated pa to the pte in the correct part
    sfence_vma();                        // refreshing the TLB
}
// ADDED: the main function of handling page fault
int choose_scfifo_page(struct proc *p)
{
    for (; p->scfifo_out_index < MAX_PSYC_PAGES; p->scfifo_out_index = next_ram_idx(p->scfifo_out_index))
    {
        pte_t *pte = walk(p->pagetable, p->ram_pages[p->scfifo_out_index].va, 0);
        if (*pte & PTE_A)
        {
            *pte &= ~PTE_A;
        }
        else
        {
            int real_out_index = p->scfifo_out_index;
            p->scfifo_out_index = next_ram_idx(p->scfifo_out_index);
            return real_out_index;
        }
    }
    panic("choose scfifo page: not supposed to happen");
}
// ADDED: choosing based on age.
int choose_nfua_page(struct proc *p)
{
    int min_age = p->ram_pages[0].age; // ? not choosing 0.
    int real_out_index = 0;
    for (int i = 1; i < MAX_PSYC_PAGES; i++)
    {
        struct ram_page rmpg = p->ram_pages[i];
        if (min_age >= rmpg.age)
        {
            min_age = rmpg.age;
            real_out_index = i;
        }
    }
    return real_out_index;
}
// ADDED: the most complex function of all time per code lines
int choose_some_page(struct proc *p)
{
    return 3;
}
// ADDED: counting ones for nao
int count_ones(uint number)
{
    int count = 0;
    while (number)
    {
        count += number & 1;
        number >>= 1;
    }
    return count;
}

// ADDED: choose page by lapa
int choose_lapa_page(struct proc *p)
{
    int min_access_count = count_ones(p->ram_pages[0].age);
    int min_age = p->ram_pages[0].age;
    int real_out_index = 0;
    for (int i = 1; i < MAX_PSYC_PAGES; i++)
    {
        struct ram_page rmpg = p->ram_pages[i];
        int age_count = count_ones(rmpg.age);
        if (min_access_count > age_count)
        {
            min_access_count = age_count;
            min_age = rmpg.age;
            real_out_index = i;
        }
        else if (min_access_count == age_count && min_age >= rmpg.age)
        {
            min_age = rmpg.age;
            real_out_index = i;
        }
    }
    return real_out_index;
}
int choose_page_to_swap(struct proc *p)
{
#if SELECTION == SCFIFO
    return choose_scfifo_page(p);
#endif
#if SELECTION == NFUA
    return choose_nfua_page(p);
#endif
#if SELECTION == LAPA
    return choose_lapa_page(p);
#endif
#if SELECTION == SOME
    return choose_some_page(p);
#endif
    return -1; //! not supposed to happen!
}

// ADDED: adding ram page
int add_ram_page(struct proc *p, uint64 va)
{
    if (!isSwapProc(p))
        return 0;

    struct ram_page *rmpg;
    int free_ram_idx;
    if ((free_ram_idx = find_free_page_in_ram(p)) < 0)
    {
        int to_swap = choose_page_to_swap(p);
        if (swapout(p, to_swap) < 0)
            return -1;
        free_ram_idx = to_swap;
    }
    rmpg = &p->ram_pages[free_ram_idx];
    rmpg->va = va;
    rmpg->state = PG_TAKEN;
    rmpg->age = 0;
    return 0;
}

// ADDED: removing ram page
int remove_page(struct proc *p, uint64 va)
{
    if (!isSwapProc(p))
        return 0;
    
// #if SELECTION == SCFIFO
//     struct ram_page free;
// #endif
    for (int i = 0; i < MAX_PSYC_PAGES; i++)
    {
        if (p->ram_pages[i].va == va && p->ram_pages[i].state == PG_TAKEN)
        {
            p->ram_pages[i].va = 0;
            p->ram_pages[i].state = PG_FREE;
            p->ram_pages[i].age = 0;
// #if SELECTION == SCFIFO
//             free = p->ram_pages[i];
//             for (; p->ram_pages[next_ram_idx(i)].state == PG_TAKEN && next_ram_idx(i) != p->scfifo_out_index; i = next_ram_idx(i))
//             {
//                 p->ram_pages[i] = p->ram_pages[next_ram_idx(i)];
//                 p->ram_pages[next_ram_idx(i)] = free;
//             }
// #endif
            return 0;
        }
    }
    for (int i = 0; i < MAX_SWAP_PAGES; i++)
    {
        if (p->swap_pages[i].va == va && p->swap_pages[i].state == PG_TAKEN)
        {
            p->swap_pages[i].va = 0;
            p->swap_pages[i].state = PG_FREE;
            return 0;
        }
    }
    return -1;
}
uint64 prepare_fulls_swap(struct proc *p, int target_idx)
{
    struct swap_page *swpg = &p->swap_pages[target_idx];
    uint64 new_pa = (uint64)kalloc();
    if (readFromSwapFile(p, (char *)new_pa, swpg->swap_location, PGSIZE) < 0)
        panic("swapin: read from swap failed");
    swpg->va = 0;
    swpg->state = PG_FREE;
    return new_pa;
}

// ADDED: THE function of the assignment - handling pagefault!
int handle_page_fault(uint64 va)
{
    struct proc *p = myproc();
    if (!isSwapProc(p))
        panic("page fault: none swap proc page fault");

    pte_t *pte = walk(p->pagetable, va, 0);
    if (pte == 0 || (!(*pte & PTE_V) && !(*pte & PTE_PG) && !(*pte & PTE_LZ)))
    {
        printf("segmentation fault\n");
        return -1;
    }

    if (*pte & PTE_V) //! should not happen
        panic("page fault: valid page");

    va = PGROUNDDOWN(va);
    if (*pte & PTE_PG) {
        int target_idx = find_page_in_swap(p, va);
        if (target_idx < 0) //! should not happen
            panic("page fault: expected page in swap");
        uint64 pa = 0;
        int free_ram_idx = find_free_page_in_ram(p);
        if (free_ram_idx < 0)
        { // there is no available space in the ram
            int to_swap = choose_page_to_swap(p);
            if (find_free_page_in_swap(p) < 0)
            {
                pa = prepare_fulls_swap(p, target_idx);
                target_idx = -1;
            }
            swapout(p, to_swap); // written the page with to_swap index to the file.
            free_ram_idx = to_swap;
        }
        if (target_idx >= 0)
        {
            if (swapin(p, target_idx, free_ram_idx) < 0)
            {
                printf("page fault: could not swap in");
                return -1;
            }
        }
        else
        {
            swapin_addr(p, pa, va, free_ram_idx);
        }
    }
    if (*pte & PTE_LZ) {
        // allocate physical address for a lazy allocation
        char *mem = kalloc();
        if (mem == 0)
            panic("page fault: failed to resolve lazy allocation");
        memset(mem, 0, PGSIZE);
        
        *pte |= PTE_V;
        *pte &= ~PTE_LZ;
        *pte = PA2PTE(mem) | PTE_FLAGS(*pte);
        sfence_vma();    // refreshing the TLB
    }
    return 0;
}

// ADDED: check if a process is participating in the swap architecture
inline int isSwapProc(struct proc *p)
{
#if SELECTION == NONE
    return 0;
#else
    return (strncmp(p->name, "initcode", sizeof(p->name)) != 0) && (strncmp(p->name, "init", sizeof(p->name)) != 0) && (strncmp(p->parent->name, "init", sizeof(p->parent->name)) != 0);
#endif
}
int get_pagefaults() {
    return myproc()->pagefaults;
}