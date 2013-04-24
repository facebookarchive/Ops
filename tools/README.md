Ops Tools
---------

This directory contains miscellaneous tools that we find useful.

* *check_aws_secgroups*:
  nagios check to verify AWS Security Groups.
  ([blog post pending](http://blog.parse.com))

* *get_zk_lock*:
  grab a Zookeeper lock for 30 seconds to synchronize cronjobs
  ([blog post](http://blog.parse.com/2013/03/11/implementing-failover-for-random-cronjobs-with-zookeeper/))

* *mongo_compact.rb*:
  tool to continuously compact a mongo replicaset
  ([blog post](http://blog.parse.com/2013/03/26/always-be-compacting/))

* *mongo_gatherops.rb*:
  tool to record a set of ops to be used to warm a secondary prior to making it primary
  ([blog post](http://blog.parse.com/2013/03/07/techniques-for-warming-up-mongodb/))

* *mongo_preheat.rb*:
  consumes the list produced by gatherops to warm a secondray.
