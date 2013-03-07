#
# Takes on input collection of fully qualified collection names (with db info) and
# scans over the collection's data and related indexes.
#
# Generate the collection list by running mongo_gatherops.rb on the primary
# and saving the output to a file.
#
# TODO: flag the verbosity.

require 'mongo'

module OpsTools
  class Preheat
    # Run full scans on collections to draw them into memory.
    # Detect collection's indexes and issues scan queries ordered on those fields as well.
    #
    # Process identifier in the context of this program.  Not true process id.
    attr_reader :pid

    # Sanity limit.
    SCAN_LIMIT = 1_000_000
    
    # namespace interpretation.
    RE_EXTRACT = /^(?<db>[^\.]+)\.(?<collection>.+)/

    # Parallelized ways
    PARALLELIZE_LIMIT = 8
    
    # Target list and process id for deciding which items of the list to process.
    def initialize(target_list, pid)
      @target_list = target_list
      @pid = pid
      @connection = Mongo::Connection.new('localhost', 27017, {:slave_ok => true})

      # Various stats for monitoring progress.
      @index_keys_processed = 0
      @rows_processed = 0
      @collections_processed = 0
      @mongo_wait_time = 0.0
      @start_time = Time.now.utc
    end
    
    # Run this instance.
    def run
      puts "Started subprocess: #{@pid}"
      iteration = 0
      while preheat(iteration) do
        puts "#{@pid} : Iteration: #{iteration}"
        iteration += 1
      end
    end
    
    # A preheat iteration.  Consists of processing a collection
    # and its indexes.
    def preheat(iteration)
      line = @target_list[iteration * PARALLELIZE_LIMIT + @pid]
      
      # Done.
      return false if line.nil?

      # May want to sanity check your namespaces here.
      puts "#{@pid} : Processing line: #{line}"

      # Extract db and collection names.
      match_data = RE_EXTRACT.match(line)
      
      db = match_data['db']
      collection = match_data['collection']

      if db.nil? || collection.nil?
        # Inform and continue.
        puts "#{@pid} : ERROR : Extraction failure on: #{line}"
        return true
      else
        puts "#{@pid} : Extracted #{db} @ #{collection} from #{line}"
      end
 
      # Extract index keys from collection.
      index_keys = find_index_keys(db, collection)
      
      # Table scan.
      index_keys << :$natural

      puts "#{@pid} : Index keys found: #{index_keys.inspect}"
 
      index_keys.each do |order_key|
        heat_collection_using_key(db, collection, order_key)
        @index_keys_processed += 1
      end
      @collections_processed += 1

      true
    end
    
    # Bounce around the index given in order to force it into memory.
    def heat_collection_using_key(db, collection, order_key)
      puts "#{@pid} : Touching collection: (#{db} : #{collection}) : #{order_key}"
      
      # Ballpark figure based on page size.
      skip_factor = 100
      
      # Scan case.
      skip_factor = 10 if order_key == :$natural

      skip_iteration = 0
      while true
        sort_param = [[order_key, Mongo::ASCENDING]]
        limit_param = 10
        skip_param = skip_iteration * limit_param * skip_factor

        timer_start = Time.now.utc
        row_count = 0
        @connection[db][collection].find().sort(sort_param).skip(skip_param).limit(limit_param).each do |row|
          row_count += 1
        end
        timer_end = Time.now.utc
        
        delta = timer_end - timer_start
        @mongo_wait_time += delta
        @rows_processed += row_count

        current_time = Time.now.utc
        puts "#{@pid} : #{row_count} rows in #{delta} wait seconds.  (#{row_count / delta} rows/sec)"
        puts "#{@pid} : Accumulated: #{@rows_processed} rows #{@mongo_wait_time} wait seconds : (#{@rows_processed / @mongo_wait_time})"
        puts "#{@pid} : Wall time: Start: #{@start_time} Now: #{current_time} Delta: #{current_time - @start_time} keys: #{@index_keys_processed} collections: #{@collections_processed}"

        break if row_count < limit_param
        break if skip_param > SCAN_LIMIT

        skip_iteration += 1
      end
    end

    # Process the collection and extract the indexes for the collection.
    # This assumes that the indexes for the collection are useful.
    def find_index_keys(db, collection)
      # Index information looks something like:
      # {
      #  "_id_"=>{"v"=>1, "key"=>{"_id"=>1}, "ns"=>"log.usage", "name"=>"_id_"},
      #  "app_1_time_1"=>{"v"=>1, "key"=>{"app"=>1, "time"=>1}, "ns"=>"log.daily",
      # ...
      # }
      
      collection_index_keys = []
      @connection[db][collection].index_information.each do |key, value|
        index_keys = value['key']
        if index_keys.size == 1
          collection_index_keys << index_keys.keys[0]
        end
      end
      
      collection_index_keys
    end

    # Distribute over several processes.
    def self.parallelize(filename)
      target_list = []
      open(filename, 'r').each do |line|
        target_list << line.chop
      end
      target_list.each {|x| puts x}

      (0...PARALLELIZE_LIMIT).each do |i|
        pid = fork do
          OpsTools::Preheat.new(target_list, i).run
        end
      end
      
      fail_count = 0
      pid_statuses = Process.waitall
      pid_statuses.each do |pid_status|
        fail_count += 1 unless pid_status[1].exitstatus == 0
      end
      
      if fail_count > 0
        return "#{fail_count} subprocesses failed."
      end

      return "All subprocesses successful."
    end
  
  end
end

if __FILE__ == $0
  raise "No filename given." unless ARGV[0]
  
  OpsTools::Preheat::parallelize(ARGV[0])
end
