#define NTHREADS 8          // ADDED: maximum number of threads in process
#define MAIN_THREAD_INDEX 0 //ADDED: the index of the main thread in the threads array.
// Saved registers for kernel context switches.

struct context
{
    uint64 ra;
    uint64 sp;

    // callee-saved
    uint64 s0;
    uint64 s1;
    uint64 s2;
    uint64 s3;
    uint64 s4;
    uint64 s5;
    uint64 s6;
    uint64 s7;
    uint64 s8;
    uint64 s9;
    uint64 s10;
    uint64 s11;
};

// Per-CPU state.
struct cpu
{
    struct proc *proc;
    struct thread *thread;  // ADDED: The thread running on this cpu, or null.
    struct context context; // swtch() here to enter scheduler().
    int noff;               // Depth of push_off() nesting.
    int intena;             // Were interrupts enabled before push_off()?
};

extern struct cpu cpus[NCPU];

// per-process data for the trap handling code in trampoline.S.
// sits in a page by itself just under the trampoline page in the
// user page table. not specially mapped in the kernel page table.
// the sscratch register points here.
// uservec in trampoline.S saves user registers in the trapframe,
// then initializes registers from the trapframe's
// kernel_sp, kernel_hartid, kernel_satp, and jumps to kernel_trap.
// usertrapret() and userret in trampoline.S set up
// the trapframe's kernel_*, restore user registers from the
// trapframe, switch to the user page table, and enter user space.
// the trapframe includes callee-saved user registers like s0-s11 because the
// return-to-user path via usertrapret() doesn't return through
// the entire kernel call stack.
struct trapframe
{
    /*   0 */ uint64 kernel_satp;   // kernel page table
    /*   8 */ uint64 kernel_sp;     // top of process's kernel stack
    /*  16 */ uint64 kernel_trap;   // usertrap()
    /*  24 */ uint64 epc;           // saved user program counter
    /*  32 */ uint64 kernel_hartid; // saved kernel tp
    /*  40 */ uint64 ra;
    /*  48 */ uint64 sp;
    /*  56 */ uint64 gp;
    /*  64 */ uint64 tp;
    /*  72 */ uint64 t0;
    /*  80 */ uint64 t1;
    /*  88 */ uint64 t2;
    /*  96 */ uint64 s0;
    /* 104 */ uint64 s1;
    /* 112 */ uint64 a0;
    /* 120 */ uint64 a1;
    /* 128 */ uint64 a2;
    /* 136 */ uint64 a3;
    /* 144 */ uint64 a4;
    /* 152 */ uint64 a5;
    /* 160 */ uint64 a6;
    /* 168 */ uint64 a7;
    /* 176 */ uint64 s2;
    /* 184 */ uint64 s3;
    /* 192 */ uint64 s4;
    /* 200 */ uint64 s5;
    /* 208 */ uint64 s6;
    /* 216 */ uint64 s7;
    /* 224 */ uint64 s8;
    /* 232 */ uint64 s9;
    /* 240 */ uint64 s10;
    /* 248 */ uint64 s11;
    /* 256 */ uint64 t3;
    /* 264 */ uint64 t4;
    /* 272 */ uint64 t5;
    /* 280 */ uint64 t6;
};

enum procstate
{
    PUNUSED,
    PUSED,
    PZOMBIE
};

// ADDED: threadstate
enum threadstate
{
    TUNUSED,
    TUSED,
    TSLEEPING,
    TRUNNABLE,
    TRUNNING,
    TZOMBIE
};

struct sigaction
{
    void (*sa_handler)(int);
    uint sigmask;
};
// ADDED: thread struct
struct thread
{
    struct spinlock lock;
    int cid;                     // Thread id in reference to it's brother threads. 
    int tid;                     // Thread id in reference to all kernel threads.
    enum threadstate state;      // Thread state
    int killed;                  // If non-zero, have been killed
    void *chan;                  // If non-zero, sleeping on chan
    struct proc *parent;         // Parent process
    uint64 kstack;               // Virtual address of kernel stack
    struct trapframe *trapframe; // data page for trampoline.S
    struct context context;      // swtch() here to run thread
    int xstate;
};


// Per-process state
struct proc
{
    struct spinlock lock;

    int pid;
    // Process ID
    //ADDED: signal stuff
    uint pending_signals;
    uint signal_mask;
    uint signal_handlers_masks[SIGNAL_SIZE];
    void *signal_handlers[SIGNAL_SIZE];
    struct trapframe *trapframe_backup;
    struct trapframe *trapframes;
    uint signal_mask_backup;
    uint handling_signal;
    int stopped; // ADDED: If non-zero, was stopped
    int killed;
    int exiting;

    int xstate; // Exit status to be returned to parent's wait

    struct thread *main_thread;

    struct thread threads[NTHREADS];
    enum procstate state;
    uint64 sz;                  // Size of process memory (bytes)
    pagetable_t pagetable;      // User page table
    struct file *ofile[NOFILE]; // Open files
    struct inode *cwd;          // Current directory
    char name[16];              // Process name (debugging)
    struct proc *parent;        // Parent process
};


// ADDED, function signatures
void handle_kernel_signals();
void handle_user_signals();
