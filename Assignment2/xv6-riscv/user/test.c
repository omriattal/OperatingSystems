#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define SIGKILL 9
#define SIGSTOP 17
#define SIGCONT 19
#define SIGIGN 1
#define print printf

struct sigaction {
    void (*sa_handler) (int);
    uint sigmask;
};
void shit_handler(int a ) {
    print("shit %d\n", a);
}
int main(int argc, char *argv[])
{
    struct sigaction act1,act2;
    act1.sa_handler = (void *) SIGIGN;
    act1.sigmask = 14;
    act2.sa_handler = (void *) SIGIGN;
    act2.sigmask = 15;
    sigaction(10,&act1,0);
    sigaction(11,&act2,0);
    int pid = fork();
    if (pid != 0) {
        kill(pid, 10);
        kill(pid, 11);
    } else {
        sleep(15);
        print("abcdefghijklmnopqrstuvwxyz\n");
    }
    exit(0);
}
