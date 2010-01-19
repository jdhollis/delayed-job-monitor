class DelayedJobMonitor < Scout::Plugin
  needs 'active_record', 'yaml'
  
  require 'active_record'
  
  class DelayedJob < ActiveRecord::Base
  end
  
  def build_report
    establish_database_connection
    
    report :total => DelayedJob.count
    report :running => DelayedJob.count(:conditions => 'locked_at IS NOT NULL')
    report :scheduled => DelayedJob.count(:conditions => ['run_at > ? AND locked_at IS NULL AND attempts = 0', Time.now.utc])
    report :failing => DelayedJob.count(:conditions => 'attempts > 0 AND failed_at IS NULL AND locked_at IS NULL')
    report :failed => DelayedJob.count(:conditions => 'failed_at IS NOT NULL')
  end

private
  
  def establish_database_connection
    config = YAML::load(IO.read(@options['rails_root'] + '/config/database.yml'))
    ActiveRecord::Base.establish_connection(config[@options['rails_env']])
  end
end
