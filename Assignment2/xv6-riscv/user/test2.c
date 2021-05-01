#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define print(s) printf("%s\n", s);
#define STACK_SIZE 4000

void func() {
    print("I got 99 problems but a thread ain't one")
    kthread_exit(7);
}

int main(int argc, char *argv[])
{
    int tid;
    int status;
    void* stack = malloc(STACK_SIZE);
    tid = kthread_create(func, stack);
    kthread_join(tid,&status);
    tid = kthread_id();
    free(stack);
    exit(0);
}
