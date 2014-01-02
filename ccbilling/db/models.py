# vim: tabstop=4 shiftwidth=4 softtabstop=4

"""
SQLAlchemy models for ccbilling.

Created on 2013.12.30

@author: gaolichuang@gmail.com
"""

from sqlalchemy import Column, Index, Integer, BigInteger, Enum, String, schema
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import ForeignKey, DateTime, Boolean, Text, Float
from sqlalchemy.orm import relationship, backref, object_mapper
from oslo.config import cfg

from nova.openstack.common.db.sqlalchemy import models

CONF = cfg.CONF
BASE = declarative_base()

class NovaBase(models.ModelBase):
    metadata = None

'''
create table
Above, the declarative_base() callable returns a new base class from
 which all mapped classes should inherit. When the class definition
 is completed, a new Table and mapper() will have been generated.
 http://docs.sqlalchemy.org/en/rel_0_9/orm/extensions/declarative.html
'''
class VmStatNotification(BASE, NovaBase):
    """Represents a running service on a host."""

    __tablename__ = 'vm_stat_notification'
    __table_args__ = ()

    id = Column('id', Integer, primary_key=True)
    flavorid = Column('flavorid', String(255))  # , ForeignKey('hosts.id'))
    status = Column('status',String(255))
    short_status = Column('short_status',String(255))
    instance_uuid = Column('instance_uuid', String(255))
    created_at = Column('created_at',DateTime)
