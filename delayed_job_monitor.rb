class DelayedJobMonitor < Scout::Plugin
  needs 'active_record', 'yaml'
  
  require 'active_record'
  
  class DelayedJob < ActiveRecord::Base
  end
  
  def build_report
    establish_database_connection
    
    failed = DelayedJob.all(:conditions => 'failed_at IS NOT NULL')
    unless failed.blank?
      previously_failed = memory(:failed) || []
      newly_failed = failed.reject { |job| previously_failed.include? job.id }
      
      newly_failed.each { |job|
        alert "Failed job #{ job.id }", "#{ job.handler }\n#{ job.last_error }"
      }
      
      remember :failed, failed.map { |j| j.id }
    else
      memory.clear
    end
    
    report :total => DelayedJob.count
    report :running => DelayedJob.count(:conditions => 'locked_at IS NOT NULL')
    report :scheduled => DelayedJob.count(:conditions => ['run_at > ? AND locked_at IS NULL AND attempts = 0', Time.now.utc])
    report :failing => DelayedJob.count(:conditions => 'attempts > 0 AND failed_at IS NULL AND locked_at IS NULL')
    report :failed => failed.size
  end
 
private
  
  def establish_database_connection
    config = YAML::load(IO.read(@options['rails_root'] + '/config/database.yml'))
    ActiveRecord::Base.establish_connection(config[@options['rails_env']])
  end
end
