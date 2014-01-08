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
> this project reference from https://github.com/aspirer/study/tree/master/nvs_monitor
