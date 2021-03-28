#include "kernel/types.h"
#include "user.h"

int main(void)
{
	int pid;
	if ((pid = fork()) > 0) {
		printf("Dad running\n");
		for(int i = 0; i <= 10; i++){
			printf("%d bottles on the wall\n", i);
		}
	} else {
		if(fork() == 0){
			if(fork() == 0){
				printf("Jesus christ that was just 10 bottles");
			}
			else{
				for(int i = 0; i < 2147483647; i++);
			}
		}
		else{
			for(int i = 0; i < 2147483647; i++);
		}
	}
    exit(0);
}