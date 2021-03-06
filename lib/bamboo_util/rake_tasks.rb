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
            
            opts.on("-c", "--config {config}", "utility configuration file", String) do |config|
              options[:config] = config
            end
            
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
                fail "variables not in json format : #{variables}"                
              end 
              options[:variables] = variable_hash if variable_hash
            end
                     
          end
          args = opt_parser.order!(ARGV) {}
          opt_parser.parse!(args)
          conf_hash = {}
          if options[:config].nil? || options[:config].empty? # no configuration file specified
            conf_hash=conf_hash.merge(options)
          else # has configuration file
            configs = nil
            File.open(options[:config], "r") do |f|
              configs= f.read()
            end
            conf_hash=JSON.parse(configs)   
            conf_hash=conf_hash.merge(options)                   
          end
          
          conf_hash = Hash[conf_hash.map { |k, v| [k.to_sym, v] }]
          #puts conf_hash
          if conf_hash[:url].nil?
            fail "Missing url"            
          end
            
          if conf_hash[:user].nil? || conf_hash[:password].nil?
            fail "Missing username or password"
          end
            
          if conf_hash[:plan].nil?
            fail "Missing plan key"
          end
            
          client= BambooUtil::Client.new(url: conf_hash[:url], user: conf_hash[:user], password: conf_hash[:password])
          
          #def queue_plan(plan, custom_revision=nil ,stage=nil, executeAllStages=true,  variables={})
          executeAllStages=true  unless conf_hash[:stage]
          success=client.queue_plan(plan: conf_hash[:plan], custom_revision: conf_hash[:revision], stage: conf_hash[:stage] ,executeAllStages: executeAllStages, variables: conf_hash[:variables])
          
          if success 
            exit 0
          else
            fail "Plan cannot not be queued"
          end
          
        end # ent task
      
      end #namesapce
      
      
    end
  end #class
end #module

BambooUtil::RakeTask.new