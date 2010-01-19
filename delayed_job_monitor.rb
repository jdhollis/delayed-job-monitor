class DelayedJobMonitor < Scout::Plugin
  needs 'activerecord', 'yaml'
  
  require 'activerecord'
  
  module Delayed
    class Job < ActiveRecord::Base
    end
  end
  
  def build_report
    establish_database_connection
    
    report :total => Delayed::Job.count
    report :running => Delayed::Job.count(:conditions => 'locked_at IS NOT NULL')
    report :scheduled => Delayed::Job.count(:conditions => ['run_at > ? AND locked_at IS NULL AND attempts = 0', Time.now.utc])
    report :failing => Delayed::Job.count(:conditions => 'attempts > 0 AND failed_at IS NULL AND locked_at IS NULL')
    report :failed => Delayed::Job.count(:conditions => 'failed_at IS NOT NULL')
  end

private
  
  def establish_database_connection
    config = YAML::load(IO.read(@options['rails_root'] + '/config/database.yml'))
    ActiveRecord::Base.establish_connection(config[@options['rails_env']])
  end
end
