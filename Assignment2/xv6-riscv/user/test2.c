#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define print(s) printf("%s\n", s);
#define STACK_SIZE 4000

void func() {
    print("I got 99 problems but a bitch ain't one\n")
    kthread_exit(0);
}

int main(int argc, char *argv[])
{
    int tid;
    int status;
    void* stack = malloc(STACK_SIZE);
    tid = kthread_create(func, stack);
    print("created successfuly")
    kthread_join(tid,&status);

    tid = kthread_id();
    free(stack);
    printf("Finished testing threads, main thread id: %d, %d\n", tid,status);
    exit(0);
}
