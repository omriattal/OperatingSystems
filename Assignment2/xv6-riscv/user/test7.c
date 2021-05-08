#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

struct sigaction
{
    void (*sa_handler)(int);
    uint sigmask;
};
int found = 0;
int counter = 0;
void sig_handler_1(int signum)
{
    counter++;
    printf("counter is: %d by %d with signum %d\n", counter, getpid(), signum);
}
void sig_handler_dummy1(int signum)
{
    return;
}
void sig_handler_dummy2(int signum)
{
    return;
}

void sig_handler_dummy4(int signum)
{
    exit(0);
}

void sig_handler5(int signum) {
    exit(7);
}

void sig_handler6(int signum) {
    exit(6);
}

int test1_modifying_sigactions()
{
    struct sigaction sigact1;
    struct sigaction sigact2;
    struct sigaction oldact;
    sigact1.sa_handler = sig_handler_dummy1;
    sigact1.sigmask = 5;
    sigact2.sa_handler = (void (*)(int))SIG_DFL;
    sigact2.sigmask = 2;
    sigaction(6, &sigact1, 0);
    sigaction(6, &sigact2, &oldact);
    if (oldact.sa_handler != sig_handler_1 || oldact.sigmask != 5)
    {
        return 0;
    }
    int pid = fork();
    if (pid == 0)
    {
        sigaction(6, 0, &oldact);
        if (oldact.sa_handler != (void *)SIG_DFL || oldact.sigmask != 2)
        {
            return 0;
        }
    }
    return -1;
}

int test2_illegal_sighandler_modifiction()
{
    struct sigaction sigact_dummy;
    sigact_dummy.sa_handler = sig_handler_dummy1;
    sigact_dummy.sigmask = 0;

    if (sigaction(SIGSTOP, &sigact_dummy, 0) == 0)
    {
        printf("FAILED: was able to change handler for SIGSTOP\n");
        return -1;
    }
    if (sigaction(SIGKILL, &sigact_dummy, 0) == 0)
    {
        printf("FAILED: was able to change handler for SIGKILL\n");
        return -1;
    }
    return 0;
}

int test3_cont_stop()
{
    int pid = fork();

    if (pid == 0)
    {
        while (1)
        {
        }
    }

    sleep(5);
    kill(pid, SIGSTOP);
    sleep(10);
    kill(pid, SIGCONT);
    sleep(30);
    kill(pid, SIGKILL);
    int status;
    wait(&status);
    return 0;
}

int test4_handling_default_kernel_signals()
{
    int pid = fork();
    if (pid > 0)
    {
        sleep(5);
        if (kill(pid, 27)) {
            return -1;
        };
        int status;
        wait(&status);
    }
    else
    {
        while(1) sleep(5);
    }
    return 0;
}

int test5_handling_user_signals() {
    struct sigaction sigact;
    sigact.sa_handler = sig_handler6;
    sigact.sigmask = 0;
    int pid;
    if((pid = fork()) < 0){
        return -1;
    }
    if (pid > 0) {
        sleep(10);
        kill(pid,11);
        int status;
        wait(&status);
        if (status == 6) {
            return 0;
        }
    } else {
        sigaction(11,&sigact,0);
        while (1) sleep(10);
    }
    return -1;
}

int test6_blocking_signal(){
    struct sigaction sigact1;
    struct sigaction sigact2;
    sigact1.sa_handler = sig_handler5;
    sigact1.sigmask = 0;
    sigact2.sa_handler = sig_handler_dummy4;
    sigact2.sigmask = 0;

    int pid = fork();
    if(pid < 0){
        return -1;
    }
    else if (pid > 0){
        sleep(15);
        kill(pid, 7);
        kill(pid, 8);
        int status;
        wait(&status);
        if(status == 7){
            return 1;
        }
        return 0;
    }
    else {
        sigprocmask(1 << 7);
        sigaction(7, &sigact1, 0);
        sigaction(8, &sigact2, 0);
        while(1) sleep(10);
    }
}

int main(int argc, char *argv[])
{

    struct test
    {
        int (*f)();
        char *s;
    } tests[] = {
        {test1_modifying_sigactions, "modifying sigactions"},
        {test2_illegal_sighandler_modifiction, "illegal sighandler modifiction"},
        {test3_cont_stop, "cont stop"},
        {test4_handling_default_kernel_signals, "handling default kernel signals"},
        {test5_handling_user_signals, "handle user space signal handler"},
        {test6_blocking_signal, "handle blocking signal"},
        {0, 0}};

    for (struct test *t = tests; t->s != 0; t++)
    {
        printf("%s: ", t->s);
        int test_status = (t->f)();
        if (!test_status)
            printf("OK\n");
        else
            printf("FAILED!\n");
    }
    exit(0);
}
