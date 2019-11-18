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

  desc "subscribes to a queue to move messages to another destination leveraging transactions"
  task :shovel => :setup do
      task_name = ARGV[0]
      dest = ENV['dest']
      unless dest
        puts "usage: rake #{task_name} dest=dest"
        exit 0
      end
    e = Esb.new
    e.shovel do |client, msg, tx|
      headers = {suppress_content_length: true, persistent: true, transaction: tx}
      client.publish dest, msg.body, msg.headers.merge(headers)
      raise "boom!"
    end

  end


end
