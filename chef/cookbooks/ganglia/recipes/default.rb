#
# Cookbook Name:: ganglia
# Recipe:: default
#
# Copyright 2011, Heavy Water Software Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node[:platform]
when "ubuntu", "debian"
  %w{ganglia-monitor ganglia-monitor-python}.each do |pkg|
    package pkg do
      action :upgrade
    end
  end
when "redhat", "centos", "fedora"
  include_recipe "ganglia::source"

  execute "copy ganglia-monitor init script" do
    command "cp " +
      "/usr/src/ganglia-#{node[:ganglia][:version]}/gmond/gmond.init " +
      "/etc/init.d/ganglia-monitor"
    not_if "test -f /etc/init.d/ganglia-monitor"
  end

  user "ganglia"
end

directory "/etc/ganglia"

# figure out which cluster(s) we should join
# this section assumes you can send to multiple ports.
ports=[]
node['ganglia']['host_cluster'].each do |k,v|
  if (v == 1 and node['ganglia']['clusterport'].has_key?(k))
    ports.push(node['ganglia']['clusterport'][k])
  end
end
if ports.empty?
  ports.push(node['ganglia']['clusterport']['default'])
end

case node[:ganglia][:unicast]
when true
  gmond_collectors = search(:node, "role:#{node['ganglia']['server_role']} AND chef_environment:#{node.chef_environment}").map {|node| node.ipaddress}
  if gmond_collectors.empty? 
     gmond_collectors = ["127.0.0.1"]
  end
  # choose to spoof hostname if we're on ec2 and have a new enough ganglia version
  gver = %x[dpkg -l ganglia-monitor |grep ganglia-monitor | awk '{print $3}']
  if (node.cloud.provider == 'ec2' && gver >= '3.2.0')
    spoof_hostname = true
  else
    spoof_hostname = false
  end
  template "/etc/ganglia/gmond.conf" do
    source "gmond_unicast.conf.erb"
    variables( :cluster_name     => node[:ganglia][:cluster_name],
               :gmond_collectors => gmond_collectors,
               :ports            => ports,
               :spoof_hostname   => spoof_hostname,
               :hostname         => node.hostname,
               :ipaddress        => node.ipaddress )
    notifies :restart, "service[ganglia-monitor]"
  end
when false
  template "/etc/ganglia/gmond.conf" do
    source "gmond.conf.erb"
    variables( :cluster_name => node[:ganglia][:cluster_name] )
    notifies :restart, "service[ganglia-monitor]"
  end
end

service "ganglia-monitor" do
  pattern "gmond"
  supports :restart => true
  action [ :enable, :start ]
end

