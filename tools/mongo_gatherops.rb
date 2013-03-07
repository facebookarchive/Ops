# Code to collect warmup information which basically consists of the
# names of the collections accessed and the number of times they were
# accessed in the evaluation period.
#
# To use, run on the mongo primary and pipe the output to a file.
#
# Output is the list of collections accessed, sorted by the number of
# collection accesses over the period.
#
# Takes a numeric command line arg denoting the number of quarter second
# samples to take before terminating.
#
# TODO make a continuous, windowed version.

require 'date'
require 'json'
require 'mongo'
require 'socket'

module OpsTools
  class WarmupStatsCollector
    # Takes the mongo connection to interrogate.
    def initialize(mongo_connection)
      @connection = mongo_connection
      @namespace_stats = {}
    end

    def valid_namespace?(namespace)
      return false if namespace.nil? or namespace.length == 0

      # Implement filters here to pay attention to the namespaces
      # you actually care about.  There are some system namespaces
      # that you should just ignore.

      # Usually of form: database.collection_name
      ns_parts = namespace.split('.')
      
      # Brundlefly: What's this?  I don't know.
      return false if ns_parts.size < 2

      # System collections per database.
      return false if ns_parts[1] == 'system'

      # Otherwise, let's keep it.
      true
    end

    # Call this repeatedly for gathering information from the associated collection.
    def accumulate
      current_ops = mongo_get_current_ops()

      # Iterate over the op records.
      current_ops.each do |op|
        namespace = nil

        # The 'ns' field is not always populated meaningfully.
        if op['ns'].size > 0
          namespace = op['ns']
        elsif op['ns'] == ''
          # Sometimes you need to dive deeper into the op record.
          if op['query'] && op['query']['findandmodify']
            namespace = op['query']['findandmodify']
            namespace = nil unless namespace.end_with?('something_important')
          end
        end

        # Increment count for encountering the namespace.
        if valid_namespace?(namespace)
          @namespace_stats[namespace] ||= 0
          @namespace_stats[namespace] += 1
        end
      end
    end

    # Get list of current ops
    def mongo_get_current_ops
      # Currentops should give all of the server ops regardless of the
      # database specified.
      return @connection['test']['$cmd.sys.inprog'].find_one()['inprog']
    end

    # Simple status page to render for internal data.
    # Note: The ordering assumes that the warmup script will not run to
    #   completion and that you are trying to get the high priority data
    #   warmed up first.
    #
    #   If the working set exceeds the memory available and you intend
    #   to run to completion, you may want to reverse the sort order
    #   to guarantee that the highly accessed data is definitely in ram.
    def dump
      sorted_stats = []
      @namespace_stats.each do |k, v|
        sorted_stats << [k, v]
      end
      sorted_stats.sort! {|x, y| y[1] <=> x[1]}
      sorted_stats.each {|x| puts x[0]}
    end

  end
end

if $0 == __FILE__
  include OpsTools

  # Actual value should probably be larger/longer in most prod environments
  # if the number of collections being accessed is large.
  # ~300 seconds
  cycles = 1200

  if ARGV[0]
    cycles = ARGV[0].to_i
  end
  
  # Assumes default port on localhost.
  mongo_connection = Mongo::Connection.new('localhost', 27017)

  # TODO progress.
  collector = WarmupStatsCollector::new(mongo_connection)
  (0...cycles).each do |x|
    collector.accumulate
    sleep(0.25)
  end

  # Output the stats.
  collector.dump
end
