#!/bin/bash

PREFIX="ceph.node"

# disk usage
#
# Example output of `df -h`:
#
# /dev/sdc1                       7.3T  4.4T  3.0T  60% /var/lib/ceph/osd/ceph-1
# /dev/sdd1                       7.3T  5.0T  2.4T  68% /var/lib/ceph/osd/ceph-2
# /dev/sde1                       7.3T  4.5T  2.9T  62% /var/lib/ceph/osd/ceph-3
#
df_output() {
    METRIC=$PREFIX".disk_utilization"

    df -h | awk -v metric=$METRIC \
        '/ceph/ { gsub("/dev/", "", $1);
                  gsub("/var/lib/ceph/osd/ceph-", "", $NF); 
                  gsub("%", "", $(NF-1)); 

	          tags = sprintf("{\"device\":\"%s\", \"osd\":\"%s\"}", $1, $NF); 

		  printf("%s%s %s\n", metric, tags, $(NF-1)); 
		}'
}

df_output

# iostats
#
# Example output of `iostat -dkxz`:
#
# Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
# sda               3.23    40.12    2.22   46.48    92.22  3189.33   134.77     0.03    0.62    2.79    0.52   0.57   2.79
# sdm               0.04     0.29   19.33    3.48  2819.07   206.92   265.38     0.05    2.17    2.16    2.26   0.23   0.53
#
# See https://arthurchiao.art/blog/systems-performance-notes-zh/ for the meanings of each column
#
iostat_output() {
    METRIC=$PREFIX".iostat"

    iostat -dkxz | awk -v metric=$METRIC \
        '/^sd/ { tags = sprintf("{\"device\":\"%s\"}", $1)

                 heading = "device merged_r_ops merged_w_ops r_ops w_ops r_kbps w_kbps avg_request_size avg_queue_size await r_await w_await svctm util"
                 n = split(heading, columns, " ")
                 for (i=2; i<=n; i++) {
                      m = metric "." columns[i]
	              printf("%s%s %s\n", m, tags, $i)
                 }
               }'
}

iostat_output
