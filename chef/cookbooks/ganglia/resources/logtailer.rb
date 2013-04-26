
actions :enable, :disable

attribute :module_name, :kind_of => String, :name_attribute => true
attribute :log_file, :kind_of => String
attribute :metric_prefix, :kind_of => String, :default => nil
attribute :frequency, :kind_of => Integer, :default => 1
attribute :options, :kind_of => Hash, :default => {}
