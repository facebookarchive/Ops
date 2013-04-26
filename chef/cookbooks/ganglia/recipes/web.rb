include_recipe "apache2"
include_recipe "apache2::mod_rewrite"

directory "/etc/ganglia-webfrontend"

htpasswd = data_bag_item("ganglia", "gangliauser")

case node[:platform]
when "ubuntu", "debian"
  package "ganglia-webfrontend"

  apache_site "000-default" do
    enable false
  end
  template "#{node['apache']['dir']}/sites-available/ganglia.conf" do
    source "apache.conf.erb"
    if ::File.symlink?("#{node['apache']['dir']}/sites-enabled/ganglia.conf")
      notifies :reload, "service[apache2]"
    end
  end
  template "/etc/ganglia-webfrontend/htpasswd.users" do
    source "gangliaweb.htpasswd.users.erb"
    mode "0644"
    variables(
      :username => htpasswd['user'],
      :password => htpasswd['htpasswd']
    )
  end
  template "/etc/ganglia-webfrontend/conf.php" do
    source "webconf.php.erb"
    mode "0644"
  end
  directory "/var/lib/ganglia/conf/" do
    owner "www-data"
    mode "0755"
  end
  apache_module "rewrite"
  apache_module "proxy"
  apache_module "proxy_http"
  apache_site "ganglia.conf"

when "redhat", "centos", "fedora"
  package "httpd"
  package "php"
  include_recipe "ganglia::source"
  include_recipe "ganglia::gmetad"

  execute "copy web directory" do
    command "cp -r web /var/www/html/ganglia"
    creates "/var/www/html/ganglia"
    cwd "/usr/src/ganglia-#{node[:ganglia][:version]}"
  end
end

# install sinatra app to expose ganglia data to other services
gem_package 'sinatra'
gem_package 'json'
#for pkg in %w{sinatra find json} do
#  gem_package pkg do
#    action :install
#  end
#end
cookbook_file "/usr/local/bin/ganglia-rrdfetch.rb" do
  source "ganglia-rrdfetch.rb"
  mode 0755
  owner "root"
end
# note - I don't think this actually works to make chef start the daemon,
# though it does work when I run it by hand.  Yay rvm!
execute "run-ganglia-rrdfetch" do
  command "start-stop-daemon --start --oknodo --background --exec /usr/local/bin/ganglia-rrdfetch.rb"
  action :run
end

