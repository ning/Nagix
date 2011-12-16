require 'rubygems'
require 'json'
require 'sinatra/base'
require 'sinatra/respond_to'
require 'haml'
require 'yaml'
require 'nagix/mk_livestatus'
require 'nagix/nagios_object'
require 'nagix/nagios_external_command'
require 'nagix/version'

module Nagix

  class App < Sinatra::Base

    register Sinatra::RespondTo

    set :app_file, __FILE__
    set :root, File.expand_path("../..", File.dirname(__FILE__))

    configure do
      config_file = nil
      if ARGV.any?
        require 'optparse'
        OptionParser.new { |op|
          op.on('-c path') { |val| config_file = val }
        }.parse!(ARGV.dup)
      end

      set :mklivestatus_socket, nil
      set :mklivestatus_log_file, nil
      set :mklivestatus_log_level, nil

      if config_file
        config = YAML.load_file(config_file)
      else
        if File.exist?(".nagixrc")
          config = YAML.load_file(".nagixrc")
        elsif File.exists?("#{ENV['HOME']}/.nagixrc")
          config = YAML.load_file("#{ENV['HOME']}/.nagixrc")
        elsif File.exists?("/etc/nagixrc")
          config = YAML.load_file("etc/nagixrc")
        end
      end

      if config
        @config = config.to_hash.each do |k,v|
          set k.to_sym, v
        end
      else
        @config = {}
      end

      set :appname, "nagix"

#      not_found do
#        haml('404')
#      end

#      error do
#        haml('500')
#      end
    end

    configure :production do
      set :show_exceptions, false
    end

    before do
      @qsparams = Rack::Utils.parse_query(request.query_string) # route does not handle query strings with duplicate names

      @filter = nil
      @columns = nil

      @columns = "Columns: " + @qsparams['attribute'].join(' ') + "\n" if @qsparams['attribute'].kind_of?(Array)
      @columns = "Columns: " + @qsparams['attribute'] + "\n" if @qsparams['attribute'].kind_of?(String)

      @lql = Nagix::MKLivestatus.new(:socket => settings.mklivestatus_socket,
                                     :log_file => settings.mklivestatus_log_file,
                                     :log_level => settings.mklivestatus_log_level)
    end

    get '/' do
      haml :index
    end

    get '/hosts/?' do
      @hosts = @lql.find(:hosts, :column => "host_name name" )
      respond_to do |wants|
        wants.html { @hosts.nil? ? not_found : haml(:hosts) }
        wants.json { @hosts.to_json }
      end
    end

    get ('foo') do
      if params[:host_name] != "" and params[:service_description] == ""
        redirect "/hosts/#{params[:host_name]}/attributes"
      elsif params[:host_name] != "" and params[:service_description] != ""
        redirect "/hosts/#{params[:host_name]}/#{params[:service_description]}/attributes"
      end

      @hosts = @lql.find("hosts",@filter,@columns)
      respond_to do |wants|
        wants.html { @hosts == nil ? not_found : haml(:hosts) }
        wants.json { @hosts.to_json }
      end
    end

    get '/hosts/:host_name/attributes' do
      @host_name = params[:host_name]
      @hosts = @lql.find(:hosts, :filter => [ "host_name = #{@host_name}", "alias = #{@host_name}", "address = #{@host_name}", "Or: 3"])
      respond_to do |wants|
        wants.html { @hosts == nil or @hosts.length == 0 ? halt(404, "Host not found") : haml(:host) }
        wants.json { @hosts.to_json }
      end
    end

    get %r{/hosts/([a-zA-Z0-9\.]+)/([a-zA-Z0-9\.\/:_-]+)/attributes} do |host_name,service_description|

      h = @lql.find(:hosts,:filter => [ "host_name = #{host_name}", "alias = #{host_name}", "address = #{host_name}", "Or: 3"], :column => "name")

      @hosts = @lql.find(:services,:filter => [ "host_name = #{h[0]['name']}", "description = #{service_description}" ])
      respond_to do |wants|
        wants.html { @hosts == nil ? halt(404, "#{host_name} Host not found") : haml(:host) }
        wants.json { @hosts.to_json }
      end
    end













    get %r{/hosts/([a-zA-Z0-9\.]+)/([a-zA-Z0-9\.\/:_-]+)/command/([A-Z_]+)} do |host_name,service_description,napixcmd|
      @host_name = host_name
      @service_description = service_description
      @napixcmd = napixcmd
      @napicxmd_params =  {}
      haml :napixcmd
#      NagiosXcmd.docurl(napixcmd) ? redirect("#{NagiosXcmd.docurl(napixcmd)}",307) : halt(404, "Nagios External Command #{napixcmd} Not Found")
    end

    post %r{/hosts/([a-zA-Z0-9\.]+)/([a-zA-Z0-9\.\/:_-]+)/command/([A-Z_]+)} do |host_name,service_description,napixcmd|

    end

    put %r{/hosts/([a-zA-Z0-9\.]+)/([a-zA-Z0-9\.\/:_-]+)/command/([A-Z_]+)} do |host_name,service_description,napixcmd|
      begin
        napixcmd_params = JSON.parse(request.body.read)
        napixcmd_params[:host_name] = host_name
        napixcmd_params[:service_description] = service_description
      rescue JSON::ParserError
        halt 400, "JSON parse error\n"
      end
      begin
        cmd = NagiosXcmd.new(napixcmd,napixcmd_params)
      rescue NagiosXcmd::Error => e
        halt 400, e.message
      end
      @lql.xcmd(cmd)
    end

    post '/hosts' do
      if params[:host_name] != "" and params[:service_description] == ""
        redirect "/hosts/#{params[:host_name]}/attributes"
      elsif params[:host_name] != "" and params[:service_description] != ""
        redirect "/hosts/#{params[:host_name]}/#{params[:service_description]}/attributes"
      else
        redirect "/"
      end
    end

    get '/nagios' do
      @items = @lql.find("status")
      respond_to do |wants|
        wants.html { @items == nil ? not_found : haml(:table) }
        wants.json { @items.to_json }
      end
    end

    run! if $0 == __FILE__

  end
end
