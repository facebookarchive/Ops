
##
## install the ganglia-logtailer package and make it available for apps
## (this also means put in a provider for instantiating ganglia-logtailer
##

# we need all the packgages installed and so on.  also, this node should have
# its own ganglia client.
include_recipe "ganglia::default"

# only install this on precise and oneiric because that's the only platform on
# which we have the package.
if (node.lsb.codename == 'precise') || (node.lsb.codename == 'oneiric')
  package "ganglia-logtailer" do
    action :upgrade
  end
end
