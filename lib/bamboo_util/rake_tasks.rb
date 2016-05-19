require 'rake'
require 'rake/tasklib'
require 'bamboo_util'
require 'rubygems'
require 'optparse'
require 'json'

module BambooUtil
  class RakeTask < ::Rake::TaskLib
  
    def initialize(*args, &task_block)
      @task_name = args.shift || "bamboo_util"
      @desc = args.shift || "BambooUtil to trigger plan build with rest api"
      define(args, &task_block)
    end
    
    def define(args, &task_block)
      task_block.call(*[self, args].slice(0, task_block.arity)) if task_block
      [
        :queue_plan
      ].each do |t|
        Rake::Task.task_defined?("bamboo_util:#{t}") && Rake::Task["bamboo_util:#{t}"].clear
      end
      
      namespace :bamboo_util do
        
        desc "Queue plan"
        task :queue_plan do
          options = {}
          opt_parser=OptionParser.new do |opts|            
            opts.banner = "Usage rake bamboo_util:queue_plan [options]"
            
            opts.on("-l", "--url {url}", "bamboo api url, like https://bamboo.entertainment.com/rest/api/latest", String) do |url|
              options[:url] = url
            end
            
            opts.on("-u", "--user {user}", "bamboo user", String) do |user|
              options[:user] = user
            end
            
            opts.on("-p", "--pass {password}", "bamboo password", String) do |pass|
              options[:password] = pass
            end
            
            opts.on("-k", "--key {directory}", "plan key", String) do |plan|
              options[:plan] = plan
            end
            
            opts.on("-s", "--stage {stage}", "plan stage", String) do |stage|
              options[:stage] = stage
            end
            
            opts.on("-v", "--revision {revision}", "code revision", String) do |revision|
              options[:revision] = revision
            end
            
            opts.on("-d", "--data {data}", "variables passing to bamboo, json format", String) do |variables|
              #need to munge variables into hash
              variable_hash = nil
              begin 
                variable_hash = JSON.parse(variables)
              rescue
                puts "variables not in json format : #{variables}"
                exit 1
              end 
              options[:variables] = variable_hash if variable_hash
            end
                     
          end
          args = opt_parser.order!(ARGV) {}
          opt_parser.parse!(args)
          
          if options[:url].nil?
            puts "Missing url"
            exit 1
          end
          
          if options[:user].nil? || options[:password].nil?
            puts "Missing username or password"
            exit 1
          end
          
          if options[:plan].nil?
            puts "Missing plan key"
            exit 1
          end
          
          client= BambooUtil::Client.new(url: options[:url], user: options[:user], password: options[:password])
          
          #def queue_plan(plan, custom_revision=nil ,stage=nil, executeAllStages=true,  variables={})
          executeAllStages=true  unless options[:stage]
          success=client.queue_plan(plan: options[:plan], custom_revision: options[:revision], stage: options[:stage] ,executeAllStages: executeAllStages, variables: options[:variables])
          
          if success 
            return 0
          else
            return 1
          end
          
        end # ent task
      
      end #namesapce
      
      
    end
  end #class
end #module

BambooUtil::RakeTask.new