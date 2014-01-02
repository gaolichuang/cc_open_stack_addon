# vim: tabstop=4 shiftwidth=4 softtabstop=4

"""
Implementation of SQLAlchemy backend.

Created on 2013.12.30

@author: gaolichuang@gmail.com
"""

import collections
import copy
import datetime
import functools
import itertools
import sys
import time
import uuid

from oslo.config import cfg

from nova import paths
from nova.ccbilling.db import models
from nova.openstack.common.db.sqlalchemy import session as db_session
from nova.openstack.common import log as logging

LOG = logging.getLogger(__name__)

_DEFAULT_SQL_CONNECTION = 'sqlite:///' + paths.state_path_def('$sqlite_db')

def set_default_session():
    db_session.set_defaults(sql_connection=_DEFAULT_SQL_CONNECTION,
                            sqlite_db='nova.sqlite')
'''
usage: you can see nova.openstack.common.db.sqlalchemy.session.py annotation for help
'''    
def power_status_change_create(values):
    status_ref = models.VmStatNotification()
    for (key, value) in values.iteritems():
        status_ref[key] = value
    status_ref.save()
    return status_ref
def power_status_change_create1(values):
    status_ref = models.VmStatNotification()
    status_ref.update(values)
    status_ref.save()
    return status_ref
def power_status_change_create2(values):
    session = db_session.get_session()
    status_ref = models.VmStatNotification()
    status_ref.update(values)
    with session.begin():
      session.add(status_ref)

