
import json
import os
import requests
import utils
from oslo.config import cfg
from nova.openstack.common import log as logging
from novaclient import exceptions

instance_opts = [
    cfg.BoolOpt('verify',
                default=False,
                help='use ssl in keystoneor not set not verify'),
    cfg.StrOpt('auth_api_server',
               default='https://192.168.8.101:5000',
               help='The url and port of keystone api'),
    cfg.StrOpt('auth_url_suffix',
               default='v2.0/tokens',
               help='The url suffix of keystone api, donot start with /'),
    cfg.StrOpt('nova_api_server',
               default='http://192.168.8.105:8774',
               help='The url and port of nova api'),
    cfg.StrOpt('nova_api_version',
               default='v2',
               help='The api version is used of nova, donot start with /'),
    cfg.StrOpt('admin_tenant_name',
               default='admin',
               help='The name of admin tenant'),
    cfg.StrOpt('admin_user_name',
               default='admin',
               help='The name of admin user'),
    cfg.StrOpt('admin_password',
               default='123456',
               help='The password of admin user'),
    cfg.StrOpt('instances_host',
               default=utils.get_host_name(),
               help='The host which used for getting instances by nova api'),
    cfg.IntOpt('request_timeout',
               default=5,
               help='The timeout seconds of getting token or instances'),
    cfg.IntOpt('token_retry_times',
               default=1,
               help='The retry times to re-get token if it is expired'),

    ]

CONF = cfg.CONF
CONF.register_opts(instance_opts)

LOG = logging.getLogger(__name__)

_SERVER_DETAIL_PATH_= 'servers/detail'
_SERVICE_LIST_ = '/os-services'

class SimpleNovaClient(object):
    USER_AGENT = 'python-simple-nova-client'
    def __init__(self):
        self.timeout = CONF.request_timeout
        self.verify_cert = CONF.verify
        self.token = None
        self.tenant_id = None
        self.http = requests.Session()
    def _http_log_req(self, method, url, kwargs):
        string_parts = ['curl -i']
        if not kwargs.get('verify', True):
            string_parts.append(' --insecure')
        string_parts.append(" '%s'" % url)
        string_parts.append(' -X %s' % method)
        for element in kwargs['headers']:
            header = ' -H "%s: %s"' % (element, kwargs['headers'][element])
            string_parts.append(header)
        if 'data' in kwargs:
            string_parts.append(" -d '%s'" % (kwargs['data']))
        LOG.debug("\nREQ: %s\n" % "".join(string_parts))

    def _http_log_resp(self, resp):
        LOG.debug(
            "RESP: [%s] %s\nRESP BODY: %s\n",
            resp.status_code,
            resp.headers,
            resp.text)

    def _request(self, url, method, **kwargs):
        kwargs.setdefault('headers', kwargs.get('headers', {}))
        kwargs['headers']['User-Agent'] = self.USER_AGENT
        kwargs['headers']['Accept'] = 'application/json'
        if 'body' in kwargs:
            kwargs['headers']['Content-Type'] = 'application/json'
            kwargs['data'] = json.dumps(kwargs['body'])
            del kwargs['body']
        if self.timeout is not None:
            kwargs.setdefault('timeout', self.timeout)

        kwargs['verify'] = self.verify_cert

        self._http_log_req(method, url, kwargs)
        resp = self.http.request(
            method,
            url,
            **kwargs)
        self._http_log_resp(resp)

        if resp.text:
            # TODO(dtroyer): verify the note below in a requests context
            # NOTE(alaski): Because force_exceptions_to_status_code=True
            # httplib2 returns a connection refused event as a 400 response.
            # To determine if it is a bad request or refused connection we need
            # to check the body.  httplib2 tests check for 'Connection refused'
            # or 'actively refused' in the body, so that's what we'll do.
            if resp.status_code == 400:
                if ('Connection refused' in resp.text or
                    'actively refused' in resp.text):
                    raise exceptions.ConnectionRefused(resp.text)
            try:
                body = json.loads(resp.text)
            except ValueError:
                body = None
        else:
            body = None

        if resp.status_code >= 400:
            raise exceptions.from_response(resp, body, url, method)

        return resp, body

    def get_token(self, **kwargs):
        if self.token:
            return self.token
        full_auth_url = os.path.join(CONF.auth_api_server, CONF.auth_url_suffix)
        kwargs['body'] = {"auth": {"tenantName": CONF.admin_tenant_name,
                                   "passwordCredentials":
                                        {"username": CONF.admin_user_name,
                                        "password": CONF.admin_password}}}
        resp,body = self._request(url = full_auth_url, method = 'POST', **kwargs)
        try:
            self.token = body['access']['token']['id']
            self.tenant_id = body['access']['token']['tenant']['id']
            LOG.info("get token: %s, belong to tenant: %s" % (self.token, self.tenant_id))
        except (TypeError, KeyError, ValueError) as e:
            LOG.error("Get token failed, url: %s, exception: %s" %
                                        (full_auth_url, e))
        return self.token,self.tenant_id

    def get_instances_on_host(self, **kwargs):
        if not CONF.instances_host:
            LOG.error("Host name is invalid")
            return []
        token,tenant_id = self.get_token()

        if token is None or tenant_id is None:
            LOG.error('Get token fail!')
            return []
        kwargs.setdefault('headers', {})['X-Auth-Token'] = token

        url_parts = [CONF.nova_api_server, CONF.nova_api_version, tenant_id, _SERVER_DETAIL_PATH_]
        uri = '/'.join(url_parts)
        params = []
        params.append("all_tenants=1")
        params.append("host=%s" % CONF.instances_host)
        full_api_url = "%s?%s" % (uri, "&".join(params))

        resp, body = self._request(full_api_url, 'GET', **kwargs)
        try:
            servers = body['servers']
            LOG.info("get server %s" % servers)
            return servers
        except (TypeError, KeyError, ValueError) as e:
            LOG.error("Get instances error, url: %s, exception: %s" %
                        (full_api_url, e))
            return []

    def get_services(self,enable = False, only_up = True, **kwargs):
        '''service should up not down'''
        resp, body = self.get_response(_SERVICE_LIST_,**kwargs)
        service = []
        for s in body['services']:
          if only_up and s['state'] != 'up':
              continue
          if enable  and s['status'] != 'enabled':
              continue
          tup = (s['binary'],s['host'])
          service.append(tup)
        LOG.debug("Get service enable: %s, only_up: %s service:%s" % (enable, only_up, service))
        return service

    def get_response(self, url_path, params = None,**kwargs):
        '''get method'''
        token,tenant_id = self.get_token()

        if token is None or tenant_id is None:
            LOG.error('Get token fail!')
            return []
        kwargs.setdefault('headers', {})['X-Auth-Token'] = token

        url_parts = [CONF.nova_api_server, CONF.nova_api_version, tenant_id,url_path]
        uri = '/'.join(url_parts)
        if params:
            uri = "%s?%s" % (uri, "&".join(params))
        return self._request(uri, 'GET', **kwargs)
