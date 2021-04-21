#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

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
    exit(0);
}
