#include "kernel/types.h"
#include "kernel/fcntl.h"
#include "kernel/stat.h"
#include "user.h"

int main(void)
{
    int pid;
    if ((pid = fork()) > 0)
    {
        int result = trace(7, pid);
        printf("the result from trace is %d and mask is %d for pid %d\n",result, getmsk(pid),pid);
    }
    else
    {
        sleep(3);
        printf("Child trace mask: %d\n" ,getmsk(getpid()));
    }

    exit(0);
}