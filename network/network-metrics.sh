#!/bin/bash
# 2020-05-09
# @ArthurChiao

PREFIX="node.network"

#######################################################################
# 1. NIC statistics
#######################################################################
nic_stats_output() {
    NIC=$1
    METRIC=$PREFIX".nic_stats";

    for f in $(ls /sys/class/net/$NIC/statistics/); do
        TAGS="{\"nic\":\"$NIC\",\"type\":\"$f\"}";
        VAL=$(cat /sys/class/net/$NIC/statistics/$f 2>/dev/null);
        echo $METRIC$TAGS $VAL;
    done
}

nic_stats_output eth0
nic_stats_output eth1

#######################################################################
# 2. Hardware Interrupts
#######################################################################
interrupts_output() {
    PATTERN=$1 # pattern string to match
    METRIC=$PREFIX".interrupts_by_cpu"

    # '$0 ~ s' in awk means matching current line with string 's', we could not
    # writing it as '/s/ { action here }', as 's' could not be passed as a
    # variable (must be a literal), see:
    # https://unix.stackexchange.com/questions/120788/pass-shell-variable-as-a-pattern-to-awk
    awk -v s=$PATTERN -v metric=$METRIC \
        '$0 ~ s { for (i=2; i<=NF-3; i++) sum[i] += $i; }
         END    { for (i=2; i<=NF-3; i++) {
                      tags = sprintf("{\"cpu\":\"%d\"}", i-2)
                      printf("%s%s %d\n", metric, tags, sum[i])
                  }
                }' /proc/interrupts

    METRIC=$PREFIX".interrupts_by_queue"
    awk -v s=$PATTERN -v metric=$METRIC \
        '$0 ~ s { sum = 0
                  for (i=2; i<=NF-3; i++) sum += $i
                  tags = sprintf("{\"queue\":\"%s\"}", $NF)
                  printf("%s%s %d\n", metric, tags, sum)
                }' /proc/interrupts
}

# interface pattern regex
# eth: intel
# mlx: mellanox
interrupts_output "eth|mlx"

#######################################################################
# 3. Software Interrupts
#######################################################################
softirqs_output() {
    METRIC=$PREFIX".softirqs"

    for d in "NET_RX" "NET_TX"; do
        awk -v metric=$METRIC -v d=$d \
            '$0 ~ d { for (i=2; i<=NF-1; i++) {
                          tags = sprintf("{\"cpu\":\"%d\", \"direction\": \"%s\"}", i-2, dir)
                          printf("%s%s %d\n", metric, tags, $i)
                      }
                    }' /proc/softirqs
    done
}

softirqs_output

#######################################################################
# 4. Kernel Processing Drops
#######################################################################
softnet_stat_output() {
    TYP=$1
    IDX=$2

    METRIC=$PREFIX".softnet_stat"
    VAL=$(awk -v i="$IDX" '{ sum += strtonum("0x"$i) } END { print sum }' /proc/net/softnet_stat)
    TAGS="{\"type\":\"$TYP\"}";

    echo $METRIC$TAGS $VAL;
}

# Format of /proc/net/softnet_stat:
#
# column 1  : received frames
# column 2  : dropped
# column 3  : time_squeeze
# column 4-8: all zeros
# column 9  : cpu_collision
# column 10 : received_rps
# column 11 : flow_limit_count
#
# http://arthurchiao.art/blog/tuning-stack-rx-zh/
softnet_stat_output "dropped" 2
softnet_stat_output "time_squeeze" 3
softnet_stat_output "cpu_collision" 9
softnet_stat_output "received_rps" 10
softnet_stat_output "flow_limit_count" 11

#######################################################################
# 5. TCP Abnormal Statistics
#######################################################################

# expected pattern
#
# $ netstat -s | grep "segments retransmited"
#    161119 segments retransmited
#
netstat_output() {
    PATTERN=$1 # regex to grep, note that this is a real regex string, which
               # may contain, e.g. end of line character '$'.
    IDX=$2     # column ID

    METRIC=$PREFIX".tcp"
    VAL=$(netstat -s | grep "$PATTERN" | awk -v i=$IDX '{print $i}')

    # generate "type" string with prefix and pattern
    #
    # 1. replace whitespaces with underlines
    # 2. remove trailing dollar symbol ('$') if there is
    #
    # e.g. "fast retransmits$" -> "fast_retransmits"
    #
    TYP=$(echo "$PATTERN" | tr ' ' '_' | sed 's/\$//g')

    TAGS="{\"type\":\"$TYP\"}";
    echo $METRIC$TAGS $VAL;
}

netstat_output "segments retransmited" 1
netstat_output "TCPLostRetransmit" 2
netstat_output "fast retransmits$" 1
netstat_output "retransmits in slow start" 1
netstat_output "classic Reno fast retransmits failed" 1
netstat_output "TCPSynRetrans" 2

netstat_output "bad segments received" 1
netstat_output "resets sent$" 1
netstat_output "connection resets received$" 1

netstat_output "connections reset due to unexpected data$" 1
netstat_output "connections reset due to early user close$" 1
