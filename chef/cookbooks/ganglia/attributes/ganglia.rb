default[:ganglia][:version] = "3.1.7"
default[:ganglia][:uri] = "http://sourceforge.net/projects/ganglia/files/ganglia%20monitoring%20core/3.1.7/ganglia-3.1.7.tar.gz/download"
default[:ganglia][:checksum] = "bb1a4953"
default[:ganglia][:cluster_name] = "default"
default[:ganglia][:grid_name] = "MyGrid"
default[:ganglia][:unicast] = true
default[:ganglia][:server_role] = "ganglia-collector"

# port assignments for each cluster
# you should overwrite this with your own cluster list in a wrapper cookbook.
default[:ganglia][:clusterport] = {
                                    "default"       => 28649,
                                    "web"           => 28650,
                                    "app"           => 28651,
                                    "db"            => 28652,
                                    "misc"          => 28653
                                  }

# this is set on the host to determine which cluster it should join
# it's a hash with one key per cluster; it should join all clusters
# that have a value of 1.  If a machine is part of two clusters,
# it will show up in both. If this isn't overridden in the role,
# it'll show up in the default cluster.
default[:ganglia][:host_cluster] = {"default" => 1}

