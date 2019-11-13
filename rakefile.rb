#encoding: utf-8

$:.unshift "."


require 'rake'
require_relative 'lib/esb'


namespace :explore do

  task :setup do
    mkdir_p "logs" unless File.exists? "logs"
    $LOGGER = Logger.new("logs/explorations.log")
  end

  desc "publish a msg"
  task :publish => :setup do
    task_name = ARGV[0]
    msg = ENV['msg']
    unless msg
      puts "usage: rake #{task_name} msg=msg"
      exit 0
    end
    e = Esb.new
    e.publish msg

  end


  desc "subscribes to a queue"
  task :subscribe => :setup do
    e = Esb.new
    e.subscribe do |msg|
      puts msg
    end

  end


end
