
Cron jobs are run in an alpine container. It uses the busybox "crond".
Scripts to be run have to be placed into the appropriate folder.


This is the crontab root file inside the container :
 ```bash
# min	hour    day	month	weekday	command
*/15	*	    *	*	    *	    run-parts /etc/periodic/15min
0	    *	    *	*	    *	    run-parts /etc/periodic/hourly
0	    2	    *	*	    *	    run-parts /etc/periodic/daily
0	    3	    *	*	    6	    run-parts /etc/periodic/weekly
0	    5	    1	*	    *	    run-parts /etc/periodic/monthly
 ```
 where `/etc/periodic/` is mapped on host filesystem at `SELKS/docker/containers-data/cron-jobs/`
