'''
Created on 2014.1.10

@author: gaolichuang
'''
import sys
import time
from oslo.config import cfg
from nova import baserpc
from nova.openstack.common import log as logging
from nova import objects
from nova import utils

from nova import context
from nova import config
import eventlet
from simpleclient import SimpleNovaClient
SERVICE_TOPIC = {'nova-compute':'compute',
                 'nova-cert':'cert',
                 'nova-scheduler':'scheduler',
                 'nova-conductor':'conductor',
                 'nova-consoleauth':'consoleauth',}
STATIC_SERVICE_LIST = [('nova-compute','compute0'),
                       ('nova-compute','compute1'),
                       ('nova-compute','compute2'),
                       ('nova-cert','nova-controller.62.9'),
                       ('nova-scheduler','nova-controller.62.9'),
                       ('nova-consoleauth','nova-controller.62.9'),
                       ('nova-conductor','nova-controller.62.9'),]

_GET_SERVICE_FROM_DB_ = True
class ServiceMonitor(object):
    def __init__(self):
        self.ctx = context.get_admin_context()
        self.client = SimpleNovaClient()
    def get_service_list(self):
        '''return   [(binary,host)]'''
        if _GET_SERVICE_FROM_DB_:
            return self.client.get_services(enable = True)
        else:
            return STATIC_SERVICE_LIST
    def ping(self,topic, args = 'foo', timeout = 10):
        base_api = baserpc.BaseAPI(topic)
        res = base_api.ping(self.ctx, args, timeout=timeout)
        print res
       
    def monitor(self, byhost = False):
        services = self.get_service_list()
        for service in services:
            try:
                topic = ServiceMonitor.get_topic(service[0])
            except:
                continue
            if byhost:
               topic = '%s.%s' % (topic, service[1])
            self.ping(topic)

    @staticmethod
    def get_topic(service):
        #return SERVICE_TOPIC[service]
        return service[5:]


def main():
    objects.register_all()
    config.parse_args(sys.argv)
    logging.setup("service_monitor")
    utils.monkey_patch()
    LOG = logging.getLogger('service_monitor')
    monitor = ServiceMonitor();
    monitor.monitor(True)
if __name__ == "__main__":
    sys.exit(main())
