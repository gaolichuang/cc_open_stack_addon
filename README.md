cc_open_stack_addon
====================

base on openstack, it is a project Container  

### project: ccbilling  
>desc:   a middleware for nova-rpc-notification, it get notification message from rabbitmq and save it to databases  
>depends module:  
>>nova   (you should put ccbilling into nova-master/nova  as its subdir)  

### project: kvm_monitor
>desc:   monitor vm (base on kvm)  status, include:
>>>cpuUsage  
>>>memUsage  
>>>networkReceive  
>>>networkTransfer  
>>>diskUsage  
>>>diskWriteRate  
>>>diskReadRate  
>>>diskWriteRequest  
>>>diskReadRequest  
>>>diskWriteDelay  
>>>diskReadDelay  
>>>diskPartition  
>>>disk_usage  
>>>loadavg_5  
>>>memUsageRate  

>this project reference from https://github.com/aspirer/study/tree/master/nvs_monitor  
>this project need to remake qemu-ga, you can see https://github.com/gaolichuang/qemu-1.5.0-dfsg/tree/qga-realpath-statvfs

### project: service_monitor
>desc: monitor internal service, which use amqp rpc in manager
>first should change some code, if eventlet thread hang, add greenthread.sleep at  nova/openstack/common/rpc/amqp.py  waiter.put
>use bascrpc ping fuction to implement this monitor

### project: ssl  
>desc:   use for nova-novncproxy support ssl request, script use to generator ssl certification

### project: migration
>desc: from bare kvm to openstack, should update nova-compute.
>document:https://drive.google.com/?usp=chrome_app#folders/0BzWB9fhjsDL1UzFLTW9DQm56VVk
>modify nova-compute document: https://docs.google.com/document/d/1hJFN6mmRmrDubRYjFEJjDeEuo1ZhX9uUCzjXmtocBp4/edit
###  nova_deploy
>some tools for deploy nova
###  cloud-init
>cloud-init update base on cloud0.6.3: modify for support multinic, should update nova.api.metadata
>document:https://docs.google.com/document/d/1RipKhQA0Ev9Y-chhfwJAOmqzynObWe75o-yciSEgzNk/edit#
