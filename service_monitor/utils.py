'''
Created on 2014.1.7

@author: gaolichuang
'''
from nova.openstack.common import log as logging
import socket

from libvirt_qemu import libvirt

LOG = logging.getLogger(__name__)

def get_domain_uuid(domain):
    try:
        return domain.UUIDString()
    except libvirt.libvirtError as e:
        LOG.error("Get domain name failed, exception: %s" % e)
        return None
    
def get_host_name():
    try:
        return socket.gethostname()
    except socket.error as e:
        LOG.error("Get host name failed, exception: %s" % e)
        return None
def is_active(domain):
    try:
        return domain.isActive()
    except libvirt.libvirtError as e:
        LOG.error("Check domain is active failed, exception: %s" % e)
        return False

