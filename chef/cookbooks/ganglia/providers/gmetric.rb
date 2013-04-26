

action :enable do

  #script
  template "/usr/local/bin/#{new_resource.script_name}-ganglia" do
    source "ganglia/#{new_resource.script_name}.gmetric.erb"
    owner "root"
    group "root"
    mode "755"
    variables :options => new_resource.options
  end

  #cron
  template "/etc/cron.d/#{new_resource.script_name}-ganglia" do
    source "ganglia/#{new_resource.script_name}.cron.erb"
    owner "root"
    group "root"
    mode "644"
    variables :options => new_resource.options
  end

end

action :disable do

  file "/usr/local/bin/#{new_resource.script_name}-ganglia" do
    action :delete
  end

  file "/etc/cron.d/#{new_resource.script_name}-ganglia" do
    action :delete
  end

end