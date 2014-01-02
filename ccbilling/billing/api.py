'''
Created on 2013.12.30

@author: gaolichuang
'''

from oslo.config import cfg

ccbilling_opts = [
    cfg.StrOpt('topic',
               default='cc-billing',
               help='the topic billing nodes listen on'),
    cfg.StrOpt('manager',
               default='nova.ccbilling.manager.CcBillingManager',
               help='full class name for the Manager for conductor'),
    cfg.IntOpt('workers',
               help='Number of workers for billing Conductor service'),
    cfg.ListOpt('event_type_white_list',
                default=['compute.instance.power_on.start','compute.instance.power_off.end'],
                help='white list of event type')
]
ccbilling_group = cfg.OptGroup(name='ccbilling',
                               title='ccbilling Options')
CONF = cfg.CONF
CONF.register_group(ccbilling_group)
CONF.register_opts(ccbilling_opts, ccbilling_group)
