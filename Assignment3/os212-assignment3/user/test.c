#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"

#define PGSIZE 4096
#define FREE_SPACE_ON_RAM 12
int main()
{
    printf("here\n");
    char *alloc = malloc(20 * PGSIZE); // 21 actually -> 13 pages are inserted to ram pages, resulting in 8 pagefaults.

    printf("Allocated\n");
    for (int i = 0; i < 40; i++)
    {
        alloc[i * PGSIZE/2] = 'a'+i;
        sleep(1);
        printf("%d\n", i);
    }
    for (int i = 0; i < 40; i++)
    {
        if (alloc[i * PGSIZE/2] == 'a'+i) {
            printf("correct\n");
        }
        sleep(1);
    }
    // for (int i = 0; i < 20; i++)
    // {
    //     printf("alloc[%d] = %c\n", i * PGSIZE, alloc[i * PGSIZE]);
    // }
    // int pid = fork();
    // if (pid == 0)
    // {
    //     printf("child printing:\n");
    //     for (int i = 0; i < 20; i++)
    //     {
    //         printf("    alloc[%d] = %c\n", i * PGSIZE, alloc[i * PGSIZE]);
    //     }
    // }
    // else if(pid > 0){
    //     wait(0);
    // }
    free(alloc);
    exit(0);
}