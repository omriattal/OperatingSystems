#include "kernel/types.h"
#include "user.h"

struct perf
{
	int ctime;		 // ADDED: creation time
	int ttime;		 // ADDED: termination time
	int stime;		 // ADDED: total time process spent in SLEEPING state
	int retime;		 // ADDED: total time process spent in RUNNABLE state
	int rutime;		 // ADDED: total time process spent in RUNNING state
	float bursttime; // ADDED: approximate estimated burst time
};

int main(void)
{
    int a = 5;
    struct perf performance;
    int hi = wait_stat(&a, &performance);
    printf("the number seven is denoted as: %d and does not actually exist!!!\n",hi);
    exit(0);
}