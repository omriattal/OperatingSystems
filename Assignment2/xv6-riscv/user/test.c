#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define print printf

struct sigaction {
    void (*sa_handler) (int);
    uint sigmask;
};

int main(int argc, char *argv[])
{
    sigret();
    exit(0);
}
