#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"

#define PGSIZE 4096
#define FREE_SPACE_ON_RAM 12
#define BLOCKS 1
int main()
{
    char *alloc = malloc(BLOCKS * PGSIZE);
    for (int i = 0; i < BLOCKS; i++)
    {
        alloc[i * PGSIZE] = 'a' + i;
        printf("%d\n", i);
    }
    for (int i = 0; i < BLOCKS; i++)
    {
        printf("alloc[%d] = %c\n", i * PGSIZE, alloc[i * PGSIZE]);
    }
    int pid = fork();
    if (pid == 0)
    {
        printf("###############\n");
        printf("child printing:\n");
        for (int i = 0; i < BLOCKS; i++)
        {
            printf("    alloc[%d] = %c\n", i * PGSIZE, alloc[i * PGSIZE]);
        }
    }
    else if(pid > 0){
        wait(0);
    }
    free(alloc);
    exit(0);
}