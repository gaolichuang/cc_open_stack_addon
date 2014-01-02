'''
Created on 2013.12.31

@author: gaolichuang
'''

from nova.openstack.common.rpc import common as rpc_common
from nova.openstack.common.rpc import serializer as rpc_serializer


class DirectRpcDispatcher(object):
    """Dispatch rpc messages according to the requested API version.

    This class can be used as the top level 'manager' for a service.  It
    contains a list of underlying managers that have an API_VERSION attribute.
    """

    def __init__(self, callbacks, serializer=None):
        """Initialize the rpc dispatcher.

        :param callbacks: List of proxy objects that are an instance
                          of a class with rpc methods exposed.  Each proxy
                          object should have an RPC_API_VERSION attribute.
        :param serializer: The Serializer object that will be used to
                           deserialize arguments before the method call and
                           to serialize the result after it returns.
        """
        self.callbacks = callbacks
        if serializer is None:
            serializer = rpc_serializer.NoOpSerializer()
        self.serializer = serializer

    def _deserialize_args(self, context, kwargs):
        """Helper method called to deserialize args before dispatch.

        This calls our serializer on each argument, returning a new set of
        args that have been deserialized.

        :param context: The request context
        :param kwargs: The arguments to be deserialized
        :returns: A new set of deserialized args
        """
        new_kwargs = dict()
        for argname, arg in kwargs.iteritems():
            new_kwargs[argname] = self.serializer.deserialize_entity(context,
                                                                     arg)
        return new_kwargs

    def dispatch(self, message_data, **kwargs):
        """Dispatch a message based on a requested version.

        :param ctxt: The request context
        :param version: The requested API version from the incoming message
        :param method: The method requested to be called by the incoming
                       message.
        :param namespace: The namespace for the requested method.  If None,
                          the dispatcher will look for a method on a callback
                          object with no namespace set.
        :param kwargs: A dict of keyword arguments to be passed to the method.

        :returns: Whatever is returned by the underlying method that gets
                  called.
        """
        print('XXXXXX')
        print(message_data)
        method = 'no_method_callback'
        had_compatible = False
        for proxyobj in self.callbacks:
            if not hasattr(proxyobj, method):
                continue            # Check for namespace compatibility
            result = getattr(proxyobj, method)(message_data, **kwargs)
            return self.serializer.serialize_entity(ctxt, result)

