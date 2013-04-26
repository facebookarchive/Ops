

action :enable do

  #python module
  template "/usr/lib/ganglia/python_modules/#{new_resource.module_name}.py" do
    source "ganglia/#{new_resource.module_name}.py.erb"
    owner "root"
    group "root"
    mode "644"
    variables :options => new_resource.options
    notifies :restart, resources(:service => "ganglia-monitor")
  end

  #configuration
  template "/etc/ganglia/conf.d/#{new_resource.module_name}.pyconf" do
    source "ganglia/#{new_resource.module_name}.pyconf.erb"
    owner "root"
    group "root"
    mode "644"
    variables :options => new_resource.options
    notifies :restart, resources(:service => "ganglia-monitor")
  end

end

action :disable do

  file "/usr/lib/ganglia/python_modules/#{new_resource.module_name}.py" do
    action :delete
    notifies :restart, resources(:service => "ganglia-monitor")
  end

  file "/etc/ganglia/conf.d/#{new_resource.module_name}.pyconf" do
    action :delete
    notifies :restart, resources(:service => "ganglia-monitor")
  end

end