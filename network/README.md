# Network Metrics

See blog [Monitoring Network Stack](https://arthurchiao.art/blog/monitoring-network-stack/) for more details.

----

Collecting metrics of Linux network stack:

* NIC statistics
* Hardware interrupts
* Software interrupts
* Kernel processing drops
* Abnormal TCP statistics

```
$ ./network-metrics.sh
node.network.nic_stats{"nic":"eth0","type":"collisions"} 0
node.network.nic_stats{"nic":"eth0","type":"multicast"} 23173383
node.network.nic_stats{"nic":"eth0","type":"rx_crc_errors"} 0
node.network.nic_stats{"nic":"eth0","type":"rx_dropped"} 0
...
node.network.interrupts_by_cpu{"cpu":"0"} 0
node.network.interrupts_by_cpu{"cpu":"1"} 20827862
node.network.interrupts_by_cpu{"cpu":"2"} 95064795
...
node.network.interrupts_by_queue{"queue":"eth0-tx-0"} 212128881
node.network.interrupts_by_queue{"queue":"eth0-rx-1"} 32314165
...
node.network.softirqs{"cpu":"0", "direction": ""} 549279
node.network.softirqs{"cpu":"1", "direction": ""} 150304006
node.network.softirqs{"cpu":"2", "direction": ""} 205702394
...
node.network.softnet_stat{"type":"dropped"} 0
node.network.softnet_stat{"type":"time_squeeze"} 4
node.network.softnet_stat{"type":"cpu_collision"} 0
node.network.softnet_stat{"type":"received_rps"} 0
node.network.softnet_stat{"type":"flow_limit_count"} 0
node.network.tcp{"type":"segments_retransmited"} 884035
node.network.tcp{"type":"TCPLostRetransmit"} 140401
node.network.tcp{"type":"fast_retransmits"} 116965
node.network.tcp{"type":"retransmits_in_slow_start"} 110144
```

Those metrics are printed in Prometheus format.
