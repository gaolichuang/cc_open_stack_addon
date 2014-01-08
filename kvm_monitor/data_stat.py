
import base64
import json
import signal
import os

import time
import log
import utils
from oslo.config import cfg


data_stat_opts = [
    cfg.IntOpt('read_file_time_out',
               default=6,
               help='The timeout seconds of reading file by qga, '
                    'note that this value `must` larger than 5s, because '
                    'the timeout of libvirt checking qga status is 5s'),
    cfg.IntOpt('read_buf_len',
               default=1024,
               help='The buffer length of reading file by qga'),
    cfg.ListOpt('net_card_list',
                default=['eth0'],
                help='The NICs which need to collect monitor data'),
    cfg.IntOpt('monitor_delay',
               default=60,
               help='The interval seconds of collecting vm monitor data')
    ]

CONF = cfg.CONF
CONF.register_opts(data_stat_opts)

LOG = log.getLogger(__name__)


'''
Get system resources usage include disk, network, cpu, memory.
CPU: get cpu usage percent.
Memory: get total memory(KB), free memory and used memory datas.
Disk: get disk read/write data((KB)), requests and used delay(ms).
Network: get network I/O datas(bytes) and vm ip.
'''
class GetSystemUsage(object):
    def __init__(self, domain, helper):
        self.domain = domain
        self.helper = helper
        self.temp = {
                    'total_cpu_time': 0L,
                    'last_cpu_idle_time': 0L,
                    'disk_read_request': 0L,
                    'disk_write_request': 0L,
                    'disk_read': 0L,
                    'disk_write': 0L,
                    'disk_read_delay': 0,
                    'disk_write_delay': 0,
                    'network_receive_bytes': 0L,
                    'network_transfer_bytes': 0L,
                    'disk_partition_info': {},
                    'timestamp': 0L
                }

    """
    The response of reading file from qga:
	"return": {
		"count": 755,
		"buf-b64": "Y3B1ICA0OTYxIDAgNTQwNiA1MzQ4MT...",
		"eof": true
	}
    """
    def _read_file_from_guest(self, file, mode='r', read_eof=False):
        cmd_open = json.dumps({"execute": "guest-file-open",
                                 "arguments": {"path": file, "mode": mode}})

        response = self.helper.exec_qga_command(self.domain, cmd_open,
                                            timeout=CONF.read_file_time_out)
        if response:
            LOG.debug("Open file response from qga: %s" % response)
            try:
                handle = json.loads(response)['return']
            except (ValueError, KeyError, TypeError) as e:
                LOG.warn("Open file by qga failed, exception: %s" % e)
                handle = None
        else:
            LOG.warn("Open file %s by qga failed" % file)
            handle = None

        if not handle:
            return None

        cmd_read = json.dumps({"execute": "guest-file-read",
                               "arguments": {"handle": handle,
                                             "count": CONF.read_buf_len}})
        read_file_b64 = None
        eof = False
        while not eof:
            response = self.helper.exec_qga_command(self.domain, cmd_read,
                                            timeout=CONF.read_file_time_out)
            if response:
                LOG.debug("Read file response from qga: %s" % response)
                try:
                    if not read_eof:
                        # don't need to read all file contents
                        eof = True
                    else:
                        eof = json.loads(response)['return']['eof']
                    read_file_b64 = json.loads(response)['return']['buf-b64']
                except (ValueError, KeyError, TypeError) as e:
                    LOG.warn("Read file by qga failed, exception: %s" % e)
                    read_file_b64 = None
                    break
            else:
                LOG.warn("Read file %s by qga failed, exception: %s" % file)
                read_file_b64 = None
                break

        cmd_close = json.dumps({"execute": "guest-file-close",
                                "arguments": {"handle": handle}})
        self.helper.exec_qga_command(self.domain, cmd_close,
                                     timeout=CONF.read_file_time_out)

        if not read_file_b64:
            return None

        try:
            read_file = base64.decodestring(read_file_b64)
            LOG.debug("File %s contents: %s" % (file, read_file))
            return read_file
        except binascii.Error as e:
            LOG.warn("Base64 decode failed, exception: %s" % e)
            return None

    def _get_cpu_usage_dict(self):
        '''
            Get CPU usage(percent) by vmstat command.
            @return: {'cpu_usage': 0.0}
        '''
        cpu_stat = self._read_file_from_guest('/proc/stat')
        if cpu_stat:
            cpu_read_line = cpu_stat.splitlines()[0]
            cpu_infos = cpu_read_line.split()[1:-1]
            total_cpu_time = 0L
            for cpu_info in cpu_infos:
                total_cpu_time += long(cpu_info)
            last_cpu_time = self.temp['total_cpu_time']
            cpu_idle_time = long(cpu_infos[3])
            last_cpu_idle_time = self.temp['last_cpu_idle_time']
            total_cpu_period = float(total_cpu_time - last_cpu_time)
            idle_cpu_period = float(cpu_idle_time - last_cpu_idle_time)

            if total_cpu_period <= 0 or idle_cpu_period < 0:
                cpu_usage = 0.0
            else:
                idle_usage = idle_cpu_period / total_cpu_period * 100
                cpu_usage = round(100 - idle_usage, 2)

            self.temp['total_cpu_time'] = total_cpu_time
            self.temp['last_cpu_idle_time'] = cpu_idle_time
        else:
            LOG.warn("Cpu usage get failed, uuid: %s" %
                        utils.get_domain_uuid(self.domain))
            cpu_usage = 0.0

        return {'cpu_usage': cpu_usage}

    def _get_loadavg_dict(self):
        '''
            Get loadavg info from /proc/loadavg.
            @return: {'loadavg_5': 4.32}
        '''
        loadavg_file_read = self._read_file_from_guest('/proc/loadavg')
        if loadavg_file_read:
            loadavg_info_line = loadavg_file_read.splitlines()[0]
            loadavg_5 = float(loadavg_info_line.split()[1])
        else:
            LOG.warn("Loadavg_5 get failed, uuid: %s" %
                        utils.get_domain_uuid(self.domain))
            loadavg_5 = 0.0

        return {'loadavg_5': loadavg_5}

    def _get_memory_usage_dict(self):
        '''
            Get memory info(MB) from /proc/meminfo.
            @return: {'total_memory': 1, 'free_memory': 1,
                      'used_memory': 1, 'memory_usage_rate': 45}
            free_memory = MemFree + Buffers + Cached
            used_memory = MemTotal - free_memory
            memory_usage_rate = used_memory * 100 / MemTotal
        '''
        mem_usage = {
            'total_memory': 0,
            'free_memory': 0,
            'used_memory': 0,
            'memory_usage_rate': 0
        }
        mem_file_read = self._read_file_from_guest('/proc/meminfo')
        if mem_file_read:
            mem_info_lines = mem_file_read.splitlines()
        else:
            LOG.warn("Mem usage get failed, uuid: %s" %
                        utils.get_domain_uuid(self.domain))
            return mem_usage

        mem_usage['total_memory'] = long(mem_info_lines[0].split()[1]) / 1024
        mem_usage['free_memory'] = (long(mem_info_lines[1].split()[1])
                       + long(mem_info_lines[2].split()[1])
                       + long(mem_info_lines[3].split()[1])) / 1024
        mem_usage['used_memory'] = (mem_usage['total_memory'] -
                                    mem_usage['free_memory'])
        mem_usage['memory_usage_rate'] = ((mem_usage['used_memory'] * 100) /
                                            mem_usage['total_memory'])

        return mem_usage

    def _get_disk_data(self):
        '''
            Use command df to get all partitions` used/available disk
            datas(MB).
            Find string start with '/dev/' and split it with '/' to get
            disks` name into dict disks. Like '/dev/vda1' to get 'vda'.
            Call _get_disk_data_by_proc() to get datas from /proc/diskstats.
            @return: {
                      'disk_read_request': 0, 'disk_write_request': 0,
                      'disk_read': 0, 'disk_write': 0, 'disk_read_delay': 1,
                      'disk_write_delay': 1, 'used_disk': 0,
                      'avail_disk': 0,
                      'disk_partition_info': {'sys': ['vda1'],
                                              'logic': ['vdb1', 'dm-0']}
                      'disk_partition_data': {'vda': {'avail_capacity': 500,
                                                      'partition_usage': 15}}
                    }
        '''
        def _get_disk_realpath(path):
            ''' for example: you get disk from /proc/mount is 
            /dev/disk/by-uuid/dd3f9691-fbcb-4f54-b4ac-9e28c08ecb2d
            it is a soft-link file to ../../vda1, we want /dev/vda1'''
            cmd_realpath = json.dumps({"execute": "guest-get-realpath",
                                       "arguments": {"path": path}})

            response = self.helper.exec_qga_command(self.domain, cmd_realpath,
                                            timeout=CONF.read_file_time_out)
            if response:
                LOG.debug("Get realpath response from qga: %s" % response)
                try:
                    return json.loads(response)['return']
                except (ValueError, KeyError, TypeError) as e:
                    LOG.warn("get realpath failed, uuid: %s, exception: %s" %
                                (utils.get_domain_uuid(self.domain), e))
                    return None
            else:
                LOG.warn("Get realpath of %s by qga failed" % path)
                return None


        def _get_mounted_disks():
            '''
                Get mounted disks/partitions from /proc/mounts.
                @return: partition:target dict: {'vda1': '/', 'dm-0': '/mnt'}
            '''
            mounted_disks = {}
            mounts_file = self._read_file_from_guest('/proc/mounts')
            if mounts_file:
                mounts = mounts_file.splitlines()
            else:
                LOG.warn("Get mounted disks failed, uuid: %s" %
                            utils.get_domain_uuid(self.domain))
                return mounted_disks

            for mount in mounts:
                if mount.startswith('/dev/'):
                    mount = mount.split()
                    realpath = _get_disk_realpath(mount[0])
                    if realpath:
                        partition = realpath.rsplit('/')[-1]
                    else:
                        partition = mount[0].rsplit('/')[-1]
                    target = mount[1]
                    if (partition not in mounted_disks and
                            target not in mounted_disks.values()
                            or (target == '/' and
                                '/' not in mounted_disks.values())):
                        mounted_disks[partition] = target

            return mounted_disks

        def _get_fs_info(path):
            """Get free/used/total space info for a filesystem

            :param path: Any dirent on the filesystem
            :returns: A dict containing:
                     :free: How much space is free (in bytes)
                     :used: How much space is used (in bytes)
                     :total: How big the filesystem is (in bytes)
            """
            def byte_to_mb(v):
                return (float(v) / 1024.0 / 1024.0)

            fs_info = {'total': 0.0,
                       'free': 0.0,
                       'used': 0.0}
            cmd_statvfs = json.dumps({"execute": "guest-get-statvfs",
                                      "arguments": {"path": path}})
            response = self.helper.exec_qga_command(self.domain, cmd_statvfs,
                                            timeout=CONF.read_file_time_out)
            if response:
                LOG.debug("Get statvfs response from qga: %s" % response)
                try:
                    hddinfo = json.loads(response)['return']
                except (ValueError, KeyError, TypeError) as e:
                    LOG.warn("Get statvfs failed, uuid: %s, exception: %s" %
                                (utils.get_domain_uuid(self.domain), e))
                    hddinfo = None
            else:
                LOG.warn("Get statvfs failed, uuid: %s" %
                            utils.get_domain_uuid(self.domain))
                return fs_info

            fs_info['total'] = byte_to_mb(hddinfo['f_frsize'] * hddinfo['f_blocks'])
            fs_info['free'] = byte_to_mb(hddinfo['f_frsize'] * hddinfo['f_bavail'])
            fs_info['used'] = byte_to_mb(hddinfo['f_frsize'] * (hddinfo['f_blocks'] -
                                    hddinfo['f_bfree']))
            return fs_info

        def _get_patition_info(disks, total_disk_info):
            partitions = {'sys': [], 'logic': []}
            for partition, target in disks.iteritems():
                fs_info = _get_fs_info(target)
                free = fs_info['free']
                used = fs_info['used']
                total = fs_info['total']
                usage = round(used * 100 / total, 2)
                total_disk_info['disk_partition_data'][partition] = {
                                        'avail_capacity': free,
                                        'partition_usage': usage
                                    }
                total_disk_info['used_disk'] += used
                total_disk_info['avail_disk'] += free
                if target == '/':
                    partitions['sys'].append(partition)
                else:
                    partitions['logic'].append(partition)

            # NOTE(hzyangtk): here to store all the partition names
            total_disk_info['disk_partition_info'] = partitions

        def _get_disk_data_by_proc(disks, total_disk_info):
            '''
                Get disks infos from /proc/diskstats, like:
                    read/write datas(KB),
                    request times(count time),
                    read/write paid time(ms) and so on.
                And set the datas into total_disk_info dict.
            '''
            partitions = disks.keys()
            diskstats = self._read_file_from_guest('/proc/diskstats')
            if diskstats:
                disk_datas = diskstats.splitlines()
            else:
                LOG.warn("Get diskstats failed, uuid: %s" %
                            utils.get_domain_uuid(self.domain))
                return

            for disk_data in disk_datas:
                datas = disk_data.split()
                if datas[2] in partitions:
                    total_disk_info['disk_read_request'] += long(datas[3])
                    total_disk_info['disk_write_request'] += long(datas[7])
                    total_disk_info['disk_read'] += long(datas[5]) / 2
                    total_disk_info['disk_write'] += long(datas[9]) / 2
                    total_disk_info['disk_read_delay'] += long(datas[6])
                    total_disk_info['disk_write_delay'] += long(datas[10])

        disks = _get_mounted_disks()
        total_disk_info = {
            'disk_read_request': 0,
            'disk_write_request': 0,
            'disk_read': 0,
            'disk_write': 0,
            'disk_read_delay': 0,
            'disk_write_delay': 0,
            'used_disk': 0,
            'avail_disk': 0,
            'disk_partition_info': {},
            'disk_partition_data': {}
        }

        if disks:
            _get_patition_info(disks, total_disk_info)
            _get_disk_data_by_proc(disks, total_disk_info)

        return total_disk_info

    def _get_disk_usage_rate_dict(self):
        '''
            Assemble all the datas collected from _get_disk_data().
            @return: {
                      'disk_read_request': 0.0, 'disk_write_rate': 0.0,
                      'disk_write_delay': 0.0, 'disk_read_delay': 0.0,
                      'disk_read_rate': 0.0, 'used_disk': 0,
                      'disk_write_request': 0, 'disk_partition_info': ['vda1'],
                      'disk_partition_data': {'vda': {'avail_capacity': 500,
                                                      'partition_usage': 15}}
                     }
        '''
        now_disk_data = self._get_disk_data()
        write_request_period_time = now_disk_data['disk_write_request'] \
                                    - self.temp['disk_write_request']
        read_request_period_time = now_disk_data['disk_read_request'] \
                                    - self.temp['disk_read_request']
        if write_request_period_time == 0:
            write_request_period_time = 1
        if read_request_period_time == 0:
            read_request_period_time = 1

        disk_write_rate = (float(now_disk_data['disk_write'] -
                                self.temp['disk_write'])) / CONF.monitor_delay
        disk_read_rate = (float(now_disk_data['disk_read'] -
                               self.temp['disk_read'])) / CONF.monitor_delay
        disk_write_request = (float(now_disk_data['disk_write_request'] -
                        self.temp['disk_write_request'])) / CONF.monitor_delay
        disk_read_request = (float(now_disk_data['disk_read_request'] -
                        self.temp['disk_read_request'])) / CONF.monitor_delay
        disk_write_delay = (float(now_disk_data['disk_write_delay'] -
            self.temp['disk_write_delay'])) / float(write_request_period_time)
        disk_read_delay = (float(now_disk_data['disk_read_delay'] -
            self.temp['disk_read_delay'])) / float(read_request_period_time)
        if (disk_write_rate < 0 or disk_read_rate < 0
                    or disk_write_request < 0 or disk_read_request < 0
                    or disk_write_delay < 0 or disk_read_delay < 0):
            LOG.warn("Disk info invalid: %s, %s, %s, %s, %s, %s" %
                        (disk_write_rate, disk_read_rate, disk_write_request,
                         disk_read_request, disk_write_delay, disk_read_delay))
            disk_write_rate = 0.0
            disk_read_rate = 0.0
            disk_write_request = 0.0
            disk_read_request = 0.0
            disk_write_delay = 0.0
            disk_read_delay = 0.0

        disk_usage_dict = {
                'used_disk': now_disk_data['used_disk'],
                'disk_write_rate': disk_write_rate,
                'disk_read_rate': disk_read_rate,
                'disk_write_request': disk_write_request,
                'disk_read_request': disk_read_request,
                'disk_write_delay': disk_write_delay,
                'disk_read_delay': disk_read_delay,
                'disk_partition_info': now_disk_data['disk_partition_info'],
                'disk_partition_data': now_disk_data['disk_partition_data']
        }

        for key in now_disk_data.keys():
            if key in self.temp:
                self.temp[key] = now_disk_data[key]

        return disk_usage_dict

    def _get_network_flow_data(self):
        '''
            Get network flow datas(Byte) from network card by
            command 'ifconfig'.
            Split the grep result and divide it into list.
            @return: ['10.120.0.1', '123', '123']
        '''
        receive_bytes = 0L
        transfer_bytes = 0L
        receive_packages = 0L
        transfer_packages = 0L
        # TODO(hzyangtk): When VM has multiple network card, it should monitor
        #                 all the cards but not only eth0.
        net_devs = self._read_file_from_guest('/proc/net/dev')
        if net_devs:
            network_lines = net_devs.splitlines()
        else:
            LOG.warn("Get network data failed, uuid: %s" %
                        utils.get_domain_uuid(self.domain))
            return [receive_bytes, transfer_bytes]
        for network_line in network_lines:
            network_datas = network_line.replace(':', ' ').split()
            try:
                if network_datas[0] in CONF.net_card_list:
                    receive_bytes += long(network_datas[1])
                    receive_packages += long(network_datas[2])
                    transfer_bytes += long(network_datas[9])
                    transfer_packages += long(network_datas[10])
            except (KeyError, ValueError, IndexError, TypeError) as e:
                LOG.warn("Get invalid network data, uuid: %s, exception: %s" %
                            (utils.get_domain_uuid(self.domain), e))
                continue
        return [receive_bytes, transfer_bytes]

    def _get_network_flow_rate_dict(self):
        '''
            Assemble dict datas collect from _get_network_flow_data()
            for network flow rate in 60s.
            Set network flow datas to self.temp.
            @return: {
                      'ip': '10.120.0.1',
                      'receive_rate': 0.0,
                      'transfer_rate': 0.0
                    }
        '''
        old_receive_bytes = self.temp['network_receive_bytes']
        old_transfer_bytes = self.temp['network_transfer_bytes']
        now_receive_bytes, now_transfer_bytes = \
                                    self._get_network_flow_data()
        receive_rate = (float(now_receive_bytes - old_receive_bytes)
                                / 1024.0 / CONF.monitor_delay)
        transfer_rate = (float(now_transfer_bytes - old_transfer_bytes)
                                / 1024.0 / CONF.monitor_delay)
        if receive_rate < 0 or transfer_rate < 0:
            LOG.warn("Get invalid network rate data: uuid: %s, %s, %s" %
                        (utils.get_domain_uuid(self.domain),
                         receive_rate, transfer_rate))
            receive_rate = 0
            transfer_rate = 0

        network_info_dict = {
                'receive_rate': receive_rate,
                'transfer_rate': transfer_rate
        }
        self.temp['network_receive_bytes'] = now_receive_bytes
        self.temp['network_transfer_bytes'] = now_transfer_bytes
        return network_info_dict

    def get_system_usage_datas(self):
        '''
            Get all system datas and assemble them into all_system_usage_dict.
            The key names of all_system_usage_dict are the same as XML setting.
        '''
        cpu_usage = self._get_cpu_usage_dict()
        loadavg = self._get_loadavg_dict()
        memory_usage = self._get_memory_usage_dict()
        network_usage = self._get_network_flow_rate_dict()
        disk_usage = {}
        disk_usage = self._get_disk_usage_rate_dict()
        all_system_usage_dict = {
            'cpuUsage': cpu_usage['cpu_usage'],
            'memUsage': memory_usage['used_memory'],
            'networkReceive': network_usage['receive_rate'],
            'networkTransfer': network_usage['transfer_rate'],
            'diskUsage': disk_usage['used_disk'],
            'diskWriteRate': disk_usage['disk_write_rate'],
            'diskReadRate': disk_usage['disk_read_rate'],
            'diskWriteRequest': disk_usage['disk_write_request'],
            'diskReadRequest': disk_usage['disk_read_request'],
            'diskWriteDelay': disk_usage['disk_write_delay'],
            'diskReadDelay': disk_usage['disk_read_delay'],
            'diskPartition': [disk_usage['disk_partition_info'],
                              disk_usage['disk_partition_data']],
            'loadavg_5': loadavg['loadavg_5'],
            'memUsageRate': memory_usage['memory_usage_rate']
        }
        LOG.info("get system from uuid: (%s), Usage:%s" %
            (utils.get_domain_uuid(self.domain),
             json.dumps(all_system_usage_dict)))
        return all_system_usage_dict

