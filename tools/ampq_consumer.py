from kombu import Connection, Exchange, Queue
from pprint import pprint

nova_x = Exchange('nova', type='topic', durable=False)
info_q = Queue('cc_billing.info', exchange=nova_x, durable=False,
                           routing_key='cc_billing.info')

def process_msg(body, message):
     print '='*80
     pprint(body)
     message.ack()

with Connection('amqp://guest:iafChewdIk2@192.168.8.35/') as conn:
    with conn.Consumer(info_q, callbacks=[process_msg]):
        while True:
            try:
                conn.drain_events()
            except KeyboardInterrupt:
                break
