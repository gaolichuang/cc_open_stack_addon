'''
consume topic target queue and save the data to database

Created on 2013.12.30

@author: gaolichuang@gmail.com
'''

import sys

from oslo.config import cfg

from nova import config
from nova import objects
from nova.openstack.common import log as logging
from nova.ccbilling.billing import service as billing_service
from nova import service
from nova import utils

CONF = cfg.CONF
CONF.import_opt('topic', 'nova.ccbilling.billing.api', group='ccbilling')


def main():
    objects.register_all()
    config.parse_args(sys.argv)
    logging.setup("ccbilling")
    utils.monkey_patch()

    server = billing_service.Service.create(binary='cc-billing',
                                    topic=CONF.ccbilling.topic,
                                    manager=CONF.ccbilling.manager)
    service.serve(server, workers=CONF.ccbilling.workers)
    service.wait()
