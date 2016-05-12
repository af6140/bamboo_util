require 'openssl'
require 'rest-client'
require 'logger'


module BambooUtil
  class Client
    
    def initialize(url: nil, user: nil , password: nil, logger: nil)
      @config = {}
      @config[:user]=user
      @config[:password] = password
      @config[:url] = url  
      
      if logger.nil?
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      else
        @logger =logger
      end
      
    end
    
    #queue plan with plankey
    def queue_plan(plan: nil , custom_revision: nil ,stage: nil, executeAllStages: true,  variables: {})
      url = queue_plan_url(plan, custom_revision, stage,executeAllStages,variables)
      puts "url = #{url}"      
      begin
        @logger.debug("url = #{url}") 
        response= RestClient::Request.execute(method: :post, url: url,
          user: @config[:user], password: @config[:password], :verify_ssl =>OpenSSL::SSL::VERIFY_NONE)
        @logger.info("plan queued successfully: #{response}")
      rescue RestClient::Exception => error
        @logger.fatal("Cannot queue plan, #{error.class}")
        response_code = error.http_code
        case response_code
        when 415 
          # post method payload is not form encoded
          @logger.fatal("post payload is not form encoded: url")
        when 400
          #plan not queued due to bamboo limitation, like too many cocurrent builds for the current plan
          @logger.fatal("bamboo limitation, too many builds queued for current plan?")
        when 404
          #plan does not exist
          @logger.fatal("current plan #{plan} not found")
        when 401
          #user pemission issue
          @logger.fatal("user #{@config[:user]} permission issue, check username and password.")
        when 405
          @logger.fatal("http method not allowd")
        when 200
          @logger.info("plan queued successfully: #{error.to_s}")
        else
          @logger.warn("Unexpected response code: #{response_code}, #{error.to_s}")
        end  
      end
      
    end
    
    def queue_plan_url(plan, custom_revision, stage, executeAllStages, variables) 
      params = {}   
      params['os_authType'] = 'basic'
      if executeAllStages
        params['executeAllStages'] = 'true'
      else
        params['stage'] = stage unless stage.nil? || stage.empty?
      end
      
      params['custom_revision'] = custom_revision unless custom_revision.nil? || custom_revision.empty?
      
      if variables
        variables.each do |key, value|
          variable_name = "bamboo.variable.#{key}"
          params[variable_name] = value unless value.nil? || value.empty?
        end
      end
      query_params = URI.encode_www_form(params)# unless params.empty?
      if query_params
        url = "#{@config[:url]}/queue/#{plan}?#{query_params}"
      else
        url = "#{@config[:url]}/queue/#{plan}"
      end
      
      url
    end # queue_plan_url
    
  end#class
end #module