

action :enable do

  #python module
  template "/usr/share/ganglia-logtailer/#{new_resource.module_name}.py" do
    source "ganglia/#{new_resource.module_name}.py.erb"
    owner "root"
    group "root"
    mode "644"
  end

  #cronjob calling the logtailer
  cron "ganglia-logtailer-#{new_resource.module_name}" do
    #changed the format of the name
    action :delete
  end
  cron "ganglia-logtailer-#{new_resource.module_name} #{new_resource.metric_prefix}" do
    #minute "*"
    # if frequency is 1, use the default.  otherwise specify
    if (new_resource.frequency != 1)
      minute "*/#{new_resource.frequency}"
    end
    #if we specified a metric_prefix, use it.
    if new_resource.metric_prefix.nil?
      metric_prefix_arg = ""
    else
      metric_prefix_arg = "--metric_prefix #{new_resource.metric_prefix}"
    end
    #build the command
    command "/usr/sbin/ganglia-logtailer #{metric_prefix_arg} --classname #{new_resource.module_name} --log_file #{new_resource.log_file} --mode cron"
  end

end

action :disable do

  #remove the cronjob calling the logtailer, leave everything else
  cron "ganglia-logtailer-#{new_resource.module_name}" do
    action :delete
  end
end
