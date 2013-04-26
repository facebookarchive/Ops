#!/usr/bin/env ruby

##
## This script exposes ganglia data for use by other apps.
## Ask it for a specific host/metric/time triplet, and it
## hands back a json string with the data.
## eg http://localhost/rrdfetch/web12/load_one/3600
## returns the last hour of the load_one metric.
##

require 'rubygems'
require 'sinatra'
require 'find'
require 'json'

$filelocations = {}

# cache the file locations so we don't need to wander the filesystem on every query.
def findFile(host, metric)
  unless $filelocations[host + metric].nil?
    puts "returning cached value of #{$filelocations[host + metric]}"
    return $filelocations[host + metric]
  end
  hostdir = []
  Find.find('/var/lib/ganglia/rrds') do |path|
    hostdir << path if path =~ /#{host}$/
  end
  metricfile = []
  Find.find(hostdir[0]) do |path|
    metricfile << path if path =~ /#{metric}.rrd$/
  end
  $filelocations[host + metric] = metricfile[0]
  return metricfile[0]
end

get '/rrdfetch/:host/:metric/:duration' do
  host = params['host']
  metric = params['metric']
  dur = params['duration']
  #sanitize elements
  unless(host =~ /^[a-z0-9_.-]+$/)
    halt "host #{host} didn't match regex."
  end
  unless(metric =~ /^[a-zA-Z0-9_.-]+$/)
    halt "metric #{metric} didn't match regex."
  end
  unless(dur =~ /^\d+$/)
    halt "dur #{dur} didn't match regex."
  end
  metricfile = findFile(host, metric)
  puts "metricfile is #{metricfile}"
  starttime = Time.now - dur.to_i
  endtime = Time.now
  puts "rrdtool fetch #{metricfile} AVERAGE --start #{starttime.strftime('%s')}"
  data = %x{rrdtool fetch #{metricfile} AVERAGE --start #{starttime.strftime('%s')}}
  mungeddata = []
  data.split("\n").each() do |line|
    (time, val) = line.split(':')
    next if time !~ /\d{8}/
    val = val.to_f
    mungeddata << {:timestamp => Time.at(time.to_i).strftime('%s'), :unit => 'Seconds', :average => val}
  end
  return mungeddata.to_json
  
end
