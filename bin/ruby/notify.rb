#!/usr/bin/env ruby

class Notify

  MINIMUM_NOTIFY_TIME = 10

  def self.run(args)
    new(args)
  end

  def initialize(args)
    @command = args.join(' ')
    show_help if args.empty?
    execute(args)
    notify unless executed_in_time?
  end

  private

  def execute(args)
    time = Time.now
    $stdout.puts `#{args.join(' ')}`
    @execution_time = Time.now - time
  end

  def notify
    if $?.exitstatus == 0
      `growlnotify -s -m "Command executed:\n#{@command}\nStatus: COMPLETED"`
    else
      `growlnotify -s -m "Command executed:\n#{@command}\nStatus: FAILED"`
    end
  end

  def executed_in_time?
    @execution_time > MINIMUM_NOTIFY_TIME ? false : true
  end

  def show_help
    $stdout.puts <<HELP
Usage: notify [COMMANDS]...[OPTIONS]

Execute any shell command through notify and get
a growl notification after execution is done.

HELP
    exit
  end

end

Notify.run(ARGV)
