#!/usr/bin/env python2
'''Collect RabbitMQ metrics via Management Plugin REST API,
output in Promethues format.

RabbitMQ managment API: https://pulse.mozilla.org/api/
CLI example: $ curl --u username:password http://localhost:15672/api/<path>
'''

import requests
from requests.auth import HTTPBasicAuth
import json
import os
import sys
import socket


class RabbitMQCollector(object):
    def __init__(self, username='guest', password='guest', api_url='http://localhost:15672/api'):
        self.username = username
        self.password = password
        self.api_url = api_url.strip("/")

    def call_api(self, path):
        url = self.api_url + "/" + path.strip("/")
        r = requests.get(url, auth=HTTPBasicAuth(self.username, self.password))
        return json.loads(r.text)

    def print_metric_str(self, metric, value, tags):
        print('%s%s %s' % (metric, tags, value))

    def print_metric(self, metric, value, tags):
        print('%s%s %.2f' % (metric, tags, value))

    def collect_queue(self):
        base = "rabbitmq.queue"

        for q in self.call_api('queues'):
            name = q.get("name", 0)

            skip = False
            for n in ["reply_", "tunnel", "agent-notifier", "compute.", "security_group"]:
                if n in name:
                    skip = True
                    break
            if skip:
                continue

            node = q.get("node", 0)
            consumers = q.get("consumers", 0)
            state = q.get("state", 0)
            tags = json.dumps({"name": name, "node": node, "consumers": str(consumers), "state": state})

            for k in ["memory", "messages", "messages_ready", "messages_unacknowledged"]:
                self.print_metric(base+"."+k, q.get(k, 0), tags)

    def collect_overview(self):
        base = "rabbitmq.overview"

        d = self.call_api('overview')

        node = d["node"]
        tags = json.dumps({"node": node})

        # version
        self.print_metric_str(base+".rabbitmq_version", d["rabbitmq_version"], tags)

        # objects total
        objs = d["object_totals"]
        for k in ["channels", "connections", "exchanges", "queues", "consumers"]:
            self.print_metric(base+"."+k, objs.get(k, 0), tags)

        # queue stats
        queue_totals = d["queue_totals"]
        for k in ["messages", "messages_ready", "messages_unacknowledged"]:
            self.print_metric(base+"."+k, queue_totals.get(k, 0), tags)

        # messages tats
        stats = d["message_stats"]
        for k in ["publish", "redeliver", "return_unroutable", "get_no_ack", "deliver_no_ack"]:
            self.print_metric(base+"."+k, stats.get(k, 0), tags)

    def collect_node(self, server):
        base = "rabbitmq.node"

        for data in self.call_api('nodes'):
            name = data.get("name", "")

            if not server in name: # only check for local node
                continue

            tags = json.dumps({"node": name})
            for k in ["net_ticktime", "running", "run_queue", "uptime",
                        "proc_total", "disk_free_alarm", "proc_used",
                        "sockets_used", "fd_used", "mem_used", "disk_free",
                        "gc_num"]:
                self.print_metric(base+"."+k, data.get(k, 0), tags)

def main():
    username, password, url = "guest", "guest", "http://localhost:15672/api"
    collector = RabbitMQCollector(username, password, url)

    collector.collect_overview()
    collector.collect_node(socket.gethostname()) # only check this node
    # collector.collect_queue() # there may be too many queues

if __name__ == '__main__':
    main()
