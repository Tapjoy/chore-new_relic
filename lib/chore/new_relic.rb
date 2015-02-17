gem 'newrelic_rpm', '>= 3.6.0'
require 'new_relic/agent/instrumentation/controller_instrumentation'

require 'chore'
require 'chore/new_relic/version'

# Reference implementation: https://github.com/newrelic/rpm/blob/master/lib/new_relic/agent/instrumentation/resque.rb
DependencyDetection.defer do
  @name = :chore

  ## The intention here is not to load this if we're on the publishing side of Chore, only consuming.
  depends_on do
    defined?(::Chore::CLI) && !NewRelic::Agent.config[:disable_chore]
  end

  executes do
    ::NewRelic::Agent.logger.info 'Installing NewRelic instrumentation'
  end

  executes do
    # Track consumption performance
    Chore::Queues::SQS::Consumer.class_eval do
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation

      add_transaction_tracer :handle_messages, :name => 'consume', :class_name => 'SQSConsumer', :category => 'OtherTransaction/Chore'
    end

    # Track processing done in the worker
    Chore::Worker.class_eval do
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation

      add_transaction_tracer :start_item, :name => 'process', :class_name => 'Worker', :category => 'OtherTransaction/ChoreJob'
      add_transaction_tracer :perform_job, :name => 'perform', :class_name => '#{args[0].name}', :category => 'OtherTransaction/ChoreJob', :params => 'args[1]'
    end

    if NewRelic::LanguageSupport.can_fork?
      ## Start the NewRelic agent in the parent process so we only have one agent thread sending data.
      ::Chore.add_hook(:before_first_fork) do
        NewRelic::Agent.manual_start(:dispatcher   => :resque, # We look close enough to resque for this to work
                                     :sync_startup => true,
                                     :start_channel_listener => true) # This lets us control which workers report where.
                                                                      # We could get fancy, but we won't really need it.
      end

      ## In the parent, setup a report channel (pipe) tied to this worker's id. Since we have the worker before we fork
      ## it's `object_id` will be the same in the child. So it's a convenient unique id for parent/child to share.
      ## The `pid` would seem to be obvious, but is slightly less trivial to access on the parent end, at the right time.
      ::Chore.add_hook(:before_fork) do |worker|
        NewRelic::Agent.register_report_channel(worker.object_id)
      end

      ::Chore.add_hook(:within_fork) do |worker, &block|
        begin
          # Reset the logger to avoid deadlocks
          NewRelic::Agent.logger = NewRelic::Agent::AgentLogger.new(NewRelic::Control.instance.root, nil)

          # Only suppress reporting Instance/Busy for forked children
          # Traced errors UI relies on having the parent process report that metric
          NewRelic::Agent.after_fork(:report_to_channel => worker.object_id, :report_instance_busy => false)
          block.call(worker)
        rescue StandardError => e
          NewRelic::Agent.agent.error_collector.notice_error(e, {:request_params => { :message => 'Error within fork.' }})
          raise e
        end
      end

      ## Before Chore worker shuts itself down, tell NewRelic to do the same.
      ::Chore.add_hook(:before_fork_shutdown) do
        # FIXME: For some reason, NewRelic hangs writing to the pipe that transmits
        # data to the parent process.  We're putting off solving this problem for now
        # by just timing out calls to NewRelic.
        begin
          Timeout.timeout(1) do
            NewRelic::Agent.shutdown
          end
        rescue Timeout::Error => ex
          Chore.logger.info("Failed to shut down NewRelic: Timeout exceeded")
        end
      end
    end

    ## Before Chore shuts itself down, tell NewRelic to do the same.
    ::Chore.add_hook(:before_shutdown) do
      NewRelic::Agent.shutdown
    end
  end
end

# call this now so it is memoized before potentially forking worker processes
NewRelic::LanguageSupport.can_fork?
