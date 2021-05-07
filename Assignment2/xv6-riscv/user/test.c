#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define SIGKILL 9
#define SIGSTOP 17
#define SIGCONT 19
#define SIGIGN 1
#define SIGSHIT 7
#define SIGASS 8
#define print printf


void butt_handler(int a);
void shit_handler(int a);
void ass_handler(int a);

struct sigaction {
    void (*sa_handler) (int);
    uint sigmask;
};

int main(int argc, char *argv[])
{
    int pid;
    print("who knows why this works: %p\n", butt_handler);
    // print("who knows why this works: %p\n", shit_handler);
    struct sigaction act1;
    act1.sa_handler = (void(*)(int)) shit_handler;
    act1.sigmask = 0;
    struct sigaction act2;
    act2.sa_handler = (void(*)(int)) ass_handler;
    act2.sigmask = 0;
    // // ((void(*)(int)) 0)(7);
    sigaction(SIGSHIT, &act1, 0);
    sigaction(SIGASS, &act2, 0);
    if ((pid = fork()) == 0) {
        while(1);
    } else {
        print("PID:%d\n",pid);
    }
    // int pid = fork();
    // if (pid != 0) {
    //     kill(pid, SIGSHIT);
    //     kill(pid, SIGASS);
    // } else {
    //     sleep(15);
    // }
    exit(0);
}

void butt_handler(int a) {
    printf("butt %d\n", a);
}

void shit_handler(int a) {
    printf("shit %d\n", a);
}

void ass_handler(int a) {
    printf("ass %d\n", a);
}
