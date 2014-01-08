'''
Created on 2014.1.7

@author: gaolichuang
'''

import data_stat
import helper as helper_
import instance
import utils
import log

LOG = log.getLogger(__name__)

def main():
    db_instances = instance.get_all_instances_on_host()
    db_uuids = [inst['id'] for inst in db_instances]
    
    helper = helper_.LibvirtQemuHelper()
    
    hyper_domains = helper.list_all_domains()
    monitor_domains_with_project_id = []
    
    for dom in hyper_domains:
        dom_uuid = dom.UUIDString()
#        if dom_uuid in db_uuids:
#            project_id = None
#            for inst in db_instances:
#                if dom_uuid == inst['id']:
#                    project_id = inst['tenant_id']
#        monitor_domains_with_project_id.append((dom, project_id))
        monitor_domains_with_project_id.append(dom)
    for dom in monitor_domains_with_project_id:
        uuid = utils.get_domain_uuid(dom)
        if not uuid:
            LOG.warn("Get domain uuid failed")
            continue

        if not utils.is_active(dom):
            LOG.info("Domain is not active, uuid: %s" % uuid)
            continue

        get_system_usage = data_stat.GetSystemUsage(dom, helper)
        get_system_usage.get_system_usage_datas()
#      print get_system_usage._get_cpu_usage_dict()
if __name__ == '__main__':
    main()
