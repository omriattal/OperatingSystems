#include "kernel/types.h"
#include "kernel/fcntl.h"
#include "kernel/stat.h"
#include "kernel/syscall.h"
#include "user.h"

int main(void)
{
    int mask = (1 << SYS_fork) | (1 << SYS_kill) | (1 << SYS_sbrk) | (1 << SYS_write);
    int fd, pid;
    trace(mask, getpid());
    fd = open("output", O_RDWR | O_CREATE);
    write(fd, "This is a test\n", 15);
    close(fd);
    sbrk(4096);
    pid = fork();
    if (pid > 0)
        kill(pid);
    else
    {
        sleep(5);
        printf("shouldn't print\n");
    }

    exit(0);
}