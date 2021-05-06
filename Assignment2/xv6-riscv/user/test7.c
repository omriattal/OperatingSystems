#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

struct sigaction {
  void (*sa_handler) (int);
  uint sigmask;
};

int counter = 0;

void sig_handler_4(int signum) {
    counter++;
    printf("counter is: %d by %d with signum %d\n", counter, getpid(), signum);
}

int test7_spawning_multiple_procs(){

    int test_status = 0;

    struct sigaction* sig_action_1 = malloc(sizeof(struct sigaction*));
    sig_action_1->sa_handler = &sig_handler_4;
    sig_action_1->sigmask = 0;

    if(sigaction(2, sig_action_1, 0) == -1)
            printf("sigaction failed\n");
    if(sigaction(3, sig_action_1, 0) == -1)
            printf("sigaction failed\n");
    if(sigaction(4, sig_action_1, 0) == -1)
            printf("sigaction failed\n");
    if(sigaction(5, sig_action_1, 0) == -1)
            printf("sigaction failed\n");

    int curr_pid = getpid();
    
    for(int i=2; i<6; i++){
        // printf("i is: %d\n", i);
        int pid = fork();
        if (pid < 0) {
            printf("fork failed! i is: %d\n", i);
            sleep(10);
            exit(1);
        }
        if(pid == 0){
            kill(curr_pid, i);
            exit(0);
        }
        else {
            //sleep(10);
        }
    }
    printf("finished loop\n");
    while(1){
        printf("here?\n");
        if(counter == 4){
            break;
        }
    }
    for(int i=2; i<6; i++){
        int status;
        wait(&status);
    }
    
    sig_action_1->sa_handler = (void*)SIG_DFL;
    sig_action_1->sigmask = 0;
    for(int i=0; i<32; i++){
        sigaction(i, sig_action_1, 0);
    }
    printf("ending\n");
    return test_status;
}

int
main(int argc, char *argv[]){

    struct test {
    int (*f)();
    char *s;
    } tests[] = {
        {test7_spawning_multiple_procs, "test7_spawning_multiple_procs"},
        {0,0}
    };

    for (struct test *t = tests; t->s != 0; t++) {
        printf("%s: ", t->s);
        int test_status = (t->f)();
        if(!test_status) printf("OK\n");
        else printf("FAILED!\n");
    }
    exit(0);  
}
