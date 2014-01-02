'''
Created on 2013.12.30

@author: gaolichuang
'''
import os
import sys

from oslo.config import cfg

from nova import conductor
from nova import context
from nova import exception
from nova.openstack.common.gettextutils import _
from nova.openstack.common import log as logging
from nova.openstack.common import rpc
from nova import servicegroup
from nova import version
from nova import service

LOG = logging.getLogger(__name__)

class Service(service.Service):
    """Service object for binaries running on hosts.

    A service takes a manager and enables rpc by listening to queues based
    on topic. It also periodically runs tasks on the manager and reports
    it state to the database services table.
    """

    def __init__(self, host, binary, topic, manager, report_interval=None,
                 periodic_enable=None, periodic_fuzzy_delay=None,
                 periodic_interval_max=None, db_allowed=True,
                 *args, **kwargs):
        super(Service, self).__init__(host, binary, topic, manager, report_interval=None,
                 periodic_enable=None, periodic_fuzzy_delay=None,
                 periodic_interval_max=None, db_allowed=True,
                 *args, **kwargs)


    def start(self):
        verstr = version.version_string_with_package()
        LOG.audit(_('Starting %(topic)s node (version %(version)s)'),
                  {'topic': self.topic, 'version': verstr})
        self.basic_config_check()
        self.manager.init_host()
        self.model_disconnected = False
        ctxt = context.get_admin_context()
        try:
            self.service_ref = self.conductor_api.service_get_by_args(ctxt,
                    self.host, self.binary)
            self.service_id = self.service_ref['id']
        except exception.NotFound:
            self.service_ref = self._create_service_ref(ctxt)

        self.manager.pre_start_hook()

        if self.backdoor_port is not None:
            self.manager.backdoor_port = self.backdoor_port

        self.conn = rpc.create_connection(new=True)
        LOG.debug(_("Creating Consumer connection for Service %s") %
                  self.topic)

        momethod_dispatcher = self.manager.create_rpc_dispatcher()

        # change here
        # Share this same connection for these Consumers
        self.conn.declare_topic_consumer(
            queue_name=self.topic,
            topic=self.topic,
            exchange_name='nova',
            callback=momethod_dispatcher,
            ack_on_error=True,
        )
#        self.conn.join_consumer_pool(topic=self.topic, pool_name=self.topic,callback=momethod_dispatcher,exchange_name='nova',ack_on_error=True)

#        node_topic = '%s.%s' % (self.topic, self.host)
#        self.conn.join_consumer_pool(topic=node_topic, pool_name=self.topic,callback=momethod_dispatcher,exchange_name='nova',ack_on_error=True)

#        self.conn.join_consumer_pool(topic=self.topic, pool_name=self.topic,callback=momethod_dispatcher,exchange_name='nova',ack_on_error=True)

        # Consume from all consumers in a thread
        self.conn.consume_in_thread()

        self.manager.post_start_hook()

        LOG.debug(_("Join ServiceGroup membership for this service %s")
                  % self.topic)
        # Add service to the ServiceGroup membership group.
        self.servicegroup_api.join(super().host, self.topic, self)

        if self.periodic_enable:
            if self.periodic_fuzzy_delay:
                initial_delay = random.randint(0, super().periodic_fuzzy_delay)
            else:
                initial_delay = None

            self.tg.add_dynamic_timer(super(Service, self).periodic_tasks,
                                     initial_delay=initial_delay,
                                     periodic_interval_max=
                                        super().periodic_interval_max)

