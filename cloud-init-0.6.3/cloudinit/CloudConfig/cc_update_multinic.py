# vi: ts=4 expandtab
#
#    Copyright (C) 2011 Canonical Ltd.
#    Copyright (C) 2012 Hewlett-Packard Development Company, L.P.
#
#    Author: Scott Moser <scott.moser@canonical.com>
#    Author: Juerg Haefliger <juerg.haefliger@hp.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License version 3, as
#    published by the Free Software Foundation.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

import cloudinit.util as util
#from cloudinit.CloudConfig import per_always

#frequency = per_always

def handle(_name, cfg, cloud, log, _args):
    nics = cloud.datasource.metadata.get('local-ipv4',None)
    if not isinstance(nics, list):
        log.debug("Not get Multi nic%s" % nics)
        return
    log.debug("get multi nic info %s" % nics)

    nics_info = "auto lo \n iface lo inet loopback \n"
    nic_template = "auto eth%s \n iface eth%s inet dhcp\n"
    i = 0
    while i < len(nics):
        nics_info += nic_template % (i,i)
        i += 1
        log.debug("add %s interfaces" % len(nics))

    util.write_file("/etc/network/interfaces", nics_info)

