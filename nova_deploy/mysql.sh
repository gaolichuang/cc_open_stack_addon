mysql -h192.168.1.108 -unova -pe0310d4f
exit
use nova
DROP TABLE IF EXISTS `vm_stat_notification`;

CREATE TABLE `vm_stat_notification` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `flavorid` varchar(255) DEFAULT NULL,
  `short_status` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `instance_uuid` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

