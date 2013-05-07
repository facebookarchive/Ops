actions :create

attribute :dbpath,       :kind_of => String, :required => true
attribute :logpath,      :kind_of => String, :required => true
attribute :port,         :kind_of => Integer, :required => true
attribute :replset,      :kind_of => String, :required => true

def initialize(*args)
  super
  @action = :create
end

