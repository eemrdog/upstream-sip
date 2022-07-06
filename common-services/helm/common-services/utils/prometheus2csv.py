"""
specify which pods to collect from
specify interval
convert memory bytes to GB
convert time to local time
additional query for K8s CPU
update io latency
update disk query to include device
replace container_fs_usage_bytes with kubelet_volume_stats_used_bytes
convert kubelet_volume_stats_used_bytes to GB
memory cache, and memory swap added in GB

"""


import datetime
import csv
import sys
import getopt
import logging
import requests

if sys.version_info[0] < 3 or sys.version_info[1] < 4:
    # python version < 3.3
    import time

    def timestamp(date):
        return time.mktime(date.timetuple())
else:
    def timestamp(date):
        return date.timestamp()


def main():
    handle_args(sys.argv[1:])
    query_metric_values()


def print_help_info():
    print('')
    print('Prometheus To CSV Help Info')
    print('python prometheus2csv.py -h <prometheus_url> --start=<start_timestamp> \
        --end=<end_timestamp> --clockSpeed=<clock_speed> --interval=<interval> \
        --pods=<".*"> | gzip > $(date +"%Y_%m_%d_%I_%M_%p")_metrics.gz ')

    if sys.version_info[0] < 3:
        print('e.g. python prometheus2csv.py --host="http://10.216.203.152:30000" \
            --start="2020-02-27 12:00:00" --end="2020-02-27 13:00:00" --clockSpeed="2596.992" \
            --interval=15s --pods=<.*pa.*> | gzip > $(date+"%Y_%m_%d_%I_%M_%p")_metrics.gz')
    else:
        print('e.g. python3 prometheus2csv.py --host="http://10.216.203.152:30000" \
            --start="2020-02-27 12:00:00" --end="2020-02-27 13:00:00" --clockSpeed="2596.992" \
            --interval=15s --pods=<.*pa.*> | gzip > $(date+"%Y_%m_%d_%I_%M_%p")_metrics.gz')


def handle_args(argv):
    global PROMETHEUS_URL
    global START
    global END
    global CLOCKSPEED
    global INTERVAL
    global PODS

    try:
        opts, args = getopt.getopt(argv, "h:s:e:c:i:p", [
                                   "host=", "start=", "end=", "clockSpeed=", "interval=", "pods="])
    except getopt.GetoptError as error:
        logging.error(error)
        print_help_info()
        sys.exit(2)

    for opt, arg in opts:
        if opt == "--host":
            PROMETHEUS_URL = arg
        elif opt == "--start":
            START = arg
        elif opt == "--end":
            END = arg
        elif opt == "--clockSpeed":
            CLOCKSPEED = arg
        elif opt == "--interval":
            INTERVAL = arg
        elif opt == "--pods":
            PODS = arg

    if PROMETHEUS_URL == '':
        logging.error(
            "You should use --host to specify your prometheus server's url, e.g. http://prometheus:30000")
        print_help_info()
        sys.exit(2)
    if START == '' and END == '':
        logging.error("You didn't specify query start&end time")
        print_help_info()
        sys.exit(2)
    if CLOCKSPEED == '':
        logging.error(
            "You didn't specify clockSpeed, to get clockspeed use command: lscpu | grep MHz ")
        print_help_info()
        sys.exit(2)
    if INTERVAL == '':
        logging.error("You didn't specify interval/step ")
        print_help_info()
        sys.exit(2)
    if PODS == '':
        logging.error("You didn't specify pod names")
        print_help_info()
        sys.exit(2)


def get_metrics_queries_map(startT, endT, clockSpeed):

    metrics_queries_map = {
        "container_cpu_usage_seconds_total_mhz":
        'sum(rate(container_cpu_usage_seconds_total{pod=~"' +
        str(PODS)+'"}[2m])) by (pod,instance) * ' +
        str(clockSpeed) + '&start=' + startT +
        '&end=' + endT + '&step='+INTERVAL,

        "container_cpu_usage_seconds_total_K8s_cpu":
        'sum(rate(container_cpu_usage_seconds_total{pod=~"' +
        str(PODS)+'"}[2m])) by (pod,instance)'
        + '&start=' + startT +
        '&end=' + endT + '&step='+INTERVAL,

        "container_memory_working_set_bytes":
        'sum(container_memory_working_set_bytes{pod=~"' +
        str(PODS)+'"}) by (pod, instance)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_memory_usage_bytes":
        'sum(container_memory_usage_bytes{pod=~"' +
        str(PODS)+'"}) by (pod, instance)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_network_receive_bytes_total":
        'sum(rate(container_network_receive_bytes_total{pod=~"' +
        str(PODS)+'"}[2m])) by (pod, instance)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_network_transmit_bytes_total":
        'sum(rate(container_network_transmit_bytes_total{pod=~"' +
        str(PODS)+'"}[2m])) by (pod, instance)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_network_receive_packets_dropped_total":
        'sum(rate(container_network_receive_packets_dropped_total{pod=~"' +
        str(PODS)+'"}[2m])) by (pod, instance)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_network_transmit_packets_dropped_total":
        'sum(rate(container_network_transmit_packets_dropped_total{pod=~"' +
        str(PODS)+'"}[2m])) by (pod, instance)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_network_receive_errors_total":
        'sum(rate(container_network_receive_errors_total{pod=~"' +
        str(PODS)+'"}[2m])) by (pod, instance)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_network_transmit_errors_total":
        'sum(rate(container_network_transmit_errors_total{pod=~"' +
        str(PODS)+'"}[2m])) by (pod, instance)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_fs_writes_bytes_total":
        'sum(rate(container_fs_writes_bytes_total{pod=~"' +
        str(PODS)+'"}[2m])) by (pod, instance, device)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_fs_reads_bytes_total":
        'sum(rate(container_fs_reads_bytes_total{pod=~"' +
        str(PODS)+'"}[2m])) by (pod, instance, device)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "kubelet_volume_stats_used_bytes":
        'kubelet_volume_stats_used_bytes{persistentvolumeclaim=~"'+str(PODS)+'"}&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_fs_reads_total":
        'sum(rate(container_fs_reads_total{pod=~"' +
        str(PODS)+'"}[2m])) by (pod, instance, device)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_fs_writes_total":
        'sum(rate(container_fs_writes_total{pod=~"' +
        str(PODS)+'"}[2m])) by (pod, instance, device)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_fs_io_time_seconds_total":
        '(sum(rate(container_fs_io_time_seconds_total{pod=~"' +
        str(PODS)+'"}[2m])) by (pod, instance))*1000 &start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_memory_cache":
        'sum(container_memory_cache{pod=~"' +
        str(PODS)+'"}) by (pod, instance)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL,

        "container_memory_swap":
        'sum(container_memory_swap{pod=~"' +
        str(PODS)+'"}) by (pod, instance)&start=' +
        startT + '&end=' + endT + '&step='+INTERVAL
    }

    return metrics_queries_map


def convert_bytes(num):
    """
    this function will convert bytes to GB
    """
    return "{:.2f}".format(num/1000000000)


def query_metric_values():

    writer = csv.writer(sys.stdout)
    writeHeader = True

    startTime_obj = datetime.datetime.strptime(START, '%Y-%m-%d %H:%M:%S')
    endTime_obj = datetime.datetime.strptime(END, '%Y-%m-%d %H:%M:%S')

    startTime = str(timestamp(startTime_obj))
    endTime = str(timestamp(endTime_obj))
    clockSpeed = CLOCKSPEED

    metrics_queries_map = get_metrics_queries_map(
        startTime, endTime, clockSpeed)

    for metric, query in metrics_queries_map.items():
        response = requests.get(
            PROMETHEUS_URL+'/api/v1/query_range?query=' + query)
        results = response.json()['data']['result']
        if writeHeader:
            writer.writerow(
                ['instance', 'pod', 'metric_name', 'timestamp', 'value'])
            writeHeader = False
        for result in results:
            if len(result['metric']) > 1:
                for i in range(0, len(result['values'])):
                    if metric in ('container_fs_writes_bytes_total',
                                  'container_fs_reads_bytes_total',
                                  'container_fs_reads_total',
                                  'container_fs_writes_total'):
                        if "\'pod\':" in str(result['metric']) and \
                            "\'device\':" in str(result['metric']) and \
                                "\'instance\':" in str(result['metric']):
                            list_row = [result['metric']['instance'], result['metric']['pod'],
                                        metric+'_'+result['metric']['device'],
                                        str(datetime.datetime.fromtimestamp(
                                            result['values'][i][0])),
                                        str(round(float(result['values'][i][1]), 2))]
                    elif metric == 'kubelet_volume_stats_used_bytes':
                        list_row = [result['metric']['instance'], PODS.split('.*')[1],
                                    metric+'_'+result['metric']['namespace']+'_' +
                                    result['metric']['persistentvolumeclaim'],
                                    str(datetime.datetime.fromtimestamp(
                                        result['values'][i][0])),
                                    str(round(float(result['values'][i][1]), 2))]
                        list_row[4] = convert_bytes(float(list_row[4]))
                    else:
                        list_row = [result['metric']['instance'], result['metric']['pod'], metric,
                                    str(datetime.datetime.fromtimestamp(
                                        result['values'][i][0])),
                                    str(round(float(result['values'][i][1]), 2))]

                    if metric in ('container_memory_working_set_bytes', 'container_memory_usage_bytes',
                                  'container_memory_cache', 'container_memory_swap'):
                        list_row[4] = convert_bytes(float(list_row[4]))
                        writer.writerow(list_row)
                    else:
                        writer.writerow(list_row)


if __name__ == "__main__":
    main()
