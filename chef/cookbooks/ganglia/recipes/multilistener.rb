
##
## start multiple copies of gmond, one for each cluster.
##

# we need all the packgages installed and so on.  also, this node should have
# its own ganglia client.
include_recipe "ganglia::default"

node['ganglia']['clusterport'].each do |clust,port|
  template "/etc/ganglia/gmond_collector_#{clust}.conf" do
    source "gmond_collector.conf.erb"
    variables( :cluster_name => clust,
               :port => port )
    notifies :restart, "service[ganglia-monitor-#{clust}]"
  end
  template "/etc/init.d/ganglia-monitor-#{clust}" do
    source "etc.init.d.gmond_collector.erb"
    variables( :cluster_name => clust,
               :port => port )
    mode 0755
    notifies :restart, "service[ganglia-monitor-#{clust}]"
  end
  service "ganglia-monitor-#{clust}" do
    pattern "gmond_collector_#{clust}.conf"
    supports :restart => true
    action [ :enable, :start ]
  end
end

metrics = {
}
search(:node, "ganglia_aggregated_metrics:* AND chef_environment:#{node.chef_environment}").each do |server|
  cluster = (server.ganglia.host_cluster.keys.select {|x| server.ganglia.host_cluster[x] == 1})[0]
  aggregated_metrics = server.ganglia.aggregated_metrics
  next if metrics[cluster]
  metrics[cluster] = aggregated_metrics.map do |metric|
    [metric['name'], metric['aggregator'], metric['units'], metric['pattern'] || "^#{metric['name']}$"]
  end
end

#puts metrics

# run the aggregator that generates all_* metrics
template '/usr/local/bin/Aggregator.py' do
  source "ganglia/Aggregator.py.erb"
  mode "0755"
  variables(
    :clusters => node['ganglia']['clusterport'],
    :metrics => metrics
  )
end
cron "aggregate-ganglia-data" do
  hour "*"
  minute "*"
  user "root"
  command "python /usr/local/bin/Aggregator.py"
end

