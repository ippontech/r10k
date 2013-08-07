require 'r10k/task'
require 'r10k/task/puppetfile'
require 'fileutils'


module R10K
module Task
module Environment
  class Deploy < R10K::Task::Base

    attr_writer :update_puppetfile

    def initialize(environment)
      @environment = environment

      @update_puppetfile = false
    end

    def call
      logger.notice "Deploying environment #{@environment.dirname}"
      @environment.sync

      if @update_puppetfile
        task = R10K::Task::Puppetfile::Sync.new(@environment.puppetfile)
        task_runner.insert_task_after(self, task)
      end
      
      perm = R10K::Task::Environment::EnsurePerm.new(@environment)
      task_runner.append_task(perm)
    end
  end
  
  
  
  class EnsurePerm < R10K::Task::Base
    
    def initialize(environment)
      @environment = environment
    end
    
    def call
      source = @environment.source
      
      logger.notice "Change source #{source.name} permissions"
      logger.notice "#{source.basedir} : user=#{source.owner},group=#{source.group},chmod=#{source.chmod}"
      
      chown_out = %x(chown -R #{source.owner} #{source.basedir}) if !source.owner.nil?
      chgrp_out = %x(chgrp -R #{source.group} #{source.basedir}) if !source.group.nil?
      chmod_out = %x(chmod -R #{source.chmod} #{source.basedir}) if !source.chmod.nil?
    end
  end
end
end
end
