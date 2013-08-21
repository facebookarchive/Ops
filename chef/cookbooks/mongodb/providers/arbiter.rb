action :create do

  # create the data directory & logs directory, chown it to mongodb
  Chef::Log.info("#{new_resource.name} creating data and logs directories")

  directory "#{new_resource.dbpath}" do
    owner "#{node[:mongodb][:user]}"
    group "#{node[:mongodb][:group]}"
    action :create
    recursive true
  end

  directory ::File.dirname(new_resource.logpath) do
    owner "#{node[:mongodb][:user]}"
    group "#{node[:mongodb][:group]}"
    action :create
  end

  # create the /config files
  Chef::Log.info("#{new_resource.name} populating config file")
  template "/etc/arbiter-#{new_resource.replset}.conf" do
    action :create
    source "mongodb.conf.erb"
    cookbook "mongodb"
    owner "root"
    group "root"
    mode "0644"
    variables("dbpath" => new_resource.dbpath, "replicaset_name" => new_resource.replset, "port" => new_resource.port, "logpath" => new_resource.logpath, "nojournal" => true)
  end

  # create the upstart script, populate it with the correct config file
  Chef::Log.info("#{new_resource.name} populating init script template")
  template "/etc/init/arbiter-#{new_resource.replset}.conf" do
    action :create
    source node[:mongodb][:init_script_template]
    cookbook "mongodb"
    group node['mongodb']['root_group']
    owner "root"
    mode "0644"
    variables("arbiter_replset" => new_resource.replset)
    if node[:mongodb][:should_restart_server]
      notifies :restart, "service[arbiter-#{new_resource.replset}]"
    end
  end

  # start it using upstart
  service "arbiter-#{new_resource.replset}" do
    provider Chef::Provider::Service::Upstart
    supports :restart => true
    action [:enable, :start]
  end

end

