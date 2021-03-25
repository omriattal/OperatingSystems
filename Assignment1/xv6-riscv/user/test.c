#include "kernel/types.h"
#include "user.h"

struct perf
{
	int ctime;		 // ADDED: creation time
	int ttime;		 // ADDED: termination time
	int stime;		 // ADDED: total time press spent in SLEEPING state
	int retime;		 // ADDED: total time process spent in RUNNABLE state
	int rutime;		 // ADDED: total time process spent in RUNNING state
	float bursttime; // ADDED: approximate estimated burst time
};

int main(void)
{
	int pid;
	if ((pid = fork()) > 0) {
		int status;
		struct perf performance;
		int cpid = wait_stat(&status, &performance);
		printf("don't you worry child pid: %d\n", cpid);
		printf("perf {\n ctime: %d\n ttime: %d\n stime: %d\n retime: %d\n rutime: %d\n}\n",
				performance.ctime, performance.ttime, performance.stime, performance.retime, performance.rutime);
	} else {
		printf("hello is it me you're looking for\n");
		for (int i = 0 ; i < 10000; i++) {
			printf(" ");
		}
		sleep(10);
	}
    exit(0);
}