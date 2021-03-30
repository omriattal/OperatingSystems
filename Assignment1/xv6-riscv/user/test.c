#include "kernel/types.h"
#include "user.h"
#define print printf
struct perf
{
	int ctime;		 // ADDED: creation time
	int ttime;		 // ADDED: termination time
	int stime;		 // ADDED: total time process spent in SLEEPING state
	int retime;		 // ADDED: total time process spent in RUNNABLE state
	int rutime;		 // ADDED: total time process spent in RUNNING state
	int average_bursttime; // ADDED: approximate average burst time
};

void print_performance(struct perf* performance) {
	printf("perf: {\nctime:%d\nttime:%d\nstime:%d\nretime:%d\nruntime:%d\naverage_bursttime:%d}\n",
	performance->ctime,performance->ttime,performance->stime,performance->retime,performance->rutime,performance->average_bursttime);
}

int main(void)
{
	int pid;
	if((pid = fork()) > 0) {
		struct perf performance;
		print("I forked and created %d\n",pid);
		wait_stat(0,&performance);
		print_performance(&performance);
	} else {
		int k = 0;
		for (int i = 0; i < 1000000000; i++)
		{
			k++;
		}
		print("k:%d\n",k);
		print("blah blah bliiii\n");
	}

	// running -> will have perf.runtime 
	// wait_stat
	// running
	// wait_stat
	exit(0);
}