'''
Created on 2013.12.30

@author: gaolichuang@gmail.com
'''
import sys

from oslo.config import cfg

from nova import manager
from nova.ccbilling.billing import dispatcher as direct_dispatcher
from nova.openstack.common.gettextutils import _
from nova.openstack.common import log as logging
from nova.ccbilling.db import api as db_api
from nova.openstack.common import timeutils

CONF = cfg.CONF
CONF.import_opt('event_type_white_list', 'nova.ccbilling.billing.api', group='ccbilling')

LOG = logging.getLogger(__name__)

short_status_dict = {
'compute.instance.power_on.start':'UP',
'compute.instance.power_off.end':'DOWN',
}
class CcBillingManager(manager.Manager):
    
    RPC_API_VERSION = '1.0'

    def __init__(self, *args, **kwargs):
        super(CcBillingManager, self).__init__(service_name='cc-billing',
                                               *args, **kwargs)
#        db_api.set_default_session()

    def create_rpc_dispatcher(self):
        '''Get the rpc dispatcher for this manager.

        If a manager would like to set an rpc API version, or support more than
        one class as the target of rpc messages, override this method.
        '''
        return self.no_method_callback

    def no_method_callback(self,message,**kwargs):
        if not isinstance(message, dict):
            LOG.warning(_("get Message does not is a dict %s") % message)
            return
        status=message.get('event_type')
        payload=message.get('payload')
        created_at=message.get('_context_timestamp')
        flavor_id = payload.get('instance_flavor_id')
        instance_id = payload.get('instance_id')
        LOG.info(_('Insert Into db info stauts ('
                   '%(status)s) '
                   'flavor id  (%(flavor)s).'
                   'instance id  (%(instance)s).create_at (%(create)s)'),
                   {'status': status,
                    'flavor': flavor_id, 'instance':instance_id, 'create':created_at})
        self._save_to_db(status,flavor_id,instance_id,created_at)

    def _save_to_db(self,status, flavorid, instance_uuid, created_at):
        if not filter_event_type(status):
            LOG.info(_("event type %s is filtered") % status)
            return
        values = {}
        values['status'] = status
        values['flavorid'] = flavorid
        values['instance_uuid'] = instance_uuid
        values['created_at'] = created_at
        convert_datetimes(values, 'created_at', 'deleted_at', 'updated_at')
        convert_short_status(values)
        db_api.power_status_change_create2(values)

def filter_event_type(event_type):
    return event_type in CONF.ccbilling.event_type_white_list

def convert_short_status(value):
    value['short_status'] = short_status_dict.get(value['status'],'NA');

def convert_datetimes(values, *datetime_keys):
    for key in values:
        if key in datetime_keys and isinstance(values[key], basestring):
            values[key] = timeutils.parse_strtime(values[key])
    return values
