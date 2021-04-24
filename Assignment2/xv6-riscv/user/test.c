#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define SIGKILL 9
#define SIGSTOP 17
#define SIGCONT 19
#define SIGIGN 1
#define SIGSHIT 7
#define print printf

struct sigaction {
    void (*sa_handler) (int);
    uint sigmask;
};

int main(int argc, char *argv[])
{
    print("who knows why this works: %p\n", butt_handler);
    struct sigaction act;
    act.sa_handler = (void(*)(int)) shit_handler;
    act.sigmask = 0;
    // ((void(*)(int)) 0)(7);
    sigaction(SIGSHIT, &act, 0);
    int pid = fork();
    if (pid != 0) {
        kill(pid, SIGSHIT);
    } else {
        sleep(15);
    }
    exit(0);
}

void butt_handler(int a) {
    printf("butt %d\n", a);
}

void shit_handler(int a) {
    printf("shit %d\n", a);
}
