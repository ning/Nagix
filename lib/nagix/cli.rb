require 'rubygems'
require 'optparse'
require 'ostruct'
require 'date'

module Nagix

  class CLI

    NAGIOS_OK = 0
    NAGIOS_WARNING = 1
    NAGIOS_CRITICAL = 2
    NAGIOS_UNKNOWN = 3

    attr_reader :options

    def initialize(me,arguments)
      @me = me
      @arguments = arguments
      @options = OpenStruct.new

      # defaults
      @options.debug = false
      @options.nagios = false
      @options.verbose = false
      @options.noop = false
      @options.format = "pipe"
      @options.cfgfile = nil
      @action = nil
    end

    def run
      if parsed_options? && arguments_valid?
        process_arguments
        process_command
      else
        output_help
        exit 127
      end
    end

    protected

      def parsed_options?
        opts = OptionParser.new
        opts.on('-V', '--version')                                                          { output_version ; exit 0 }
        opts.on('-h', '--help')                                                             { output_help ; exit 0}
        opts.on('-d', '--debug', "Debug mode" )                                             { @options.debug = true }
        opts.on('-v', '--verbose', "Verbose Mode")                                          { @options.verbose = true }
        opts.on('-f', '--format FORMAT', String, "Output format: raw, pipe, json")          { |format| @options.format = format }
        opts.on('-n', '--noop', "Dry-run mode")                                             { @options.noop = true }
        opts.on('-c', '--config CONFIG', String, "Configuration file location")             { |cfgfile| @options.cfgfile = cfgfile }

        opts.parse!(@arguments) rescue return false

        process_options
        true
      end

      def arguments_valid?
        if @arguments.length < 1 or @arguments.length > 2
          $stderr.puts "#{ME}: error: invalid number of arguments: #{@arguments}"
          return false
        end
        true
      end

      def process_options
        Nagix.nagios = @options.nagios if @options.nagios
        Nagix.debug = @options.debug if @options.debug
        Nagix.verbose = @options.verbose if @options.verbose
        Nagix.cfgfile = @options.cfgfile if @options.cfgfile
        Nagix.format = @options.format if @options.format
        Nagix.noop = @options.noop if @options.noop
      end

      def process_arguments
        case @arguments.length
          when 2 then
            @action = @arguments[0]
            @action_arguments = @arguments[1]
          when 1 then
            @action = @arguments[0]
            @action_arguments = nil
          else
            return false
        end

        # verify action is valid
      end

      def process_command

        gogogo(@action,@action_arguments)

        mpid, mstdin, mstdout, mstderr = popen4("svcadm enable -s $FMRI")
      end

      def output_version
        $stderr.write "#{VERSION}\n"
      end

      def output_help
        $stderr.write "#{ME} [<options>] <action> [<args>]\n"
        $stderr.write "          <options>: -d, --debug: enable debug mode\n"
        $stderr.write "                     -v, --debose: enable verbose mode\n"
        $stderr.write "                     -f, --format: format mode: pipe or row\n"
        $stderr.write "                     -n, --nop: enable dry-run mode\n"
        $stderr.write "                     -h, --help: help\n"
        $stderr.write "           <action>: start: starts Nagios\n"
        $stderr.write "                     stop: stops Nagios\n"
        $stderr.write "                     reload: reloads Nagios configuration\n"
        $stderr.write "                     status: prints SMF status of Nagios service\n"
        $stderr.write "                     pid: prints pid of Nagios daemon\n"
        $stderr.write "                     verify: verifies Nagios configuration\n"
        $stderr.write "                     find: locates a host, service or servicegroup\n"
        $stderr.write "                     list hosts|services|servicegroups: lists hosts, services or servicegroups known to Nagios\n"
        $stderr.write "                     query <args>: queries the running Nagios process\n"
        $stderr.write "                     enable notification <host>|<service>|all: enables notification for host, service, or service,host pair\n"
        $stderr.write "                     disable notification <host>|<service>|all: disables notification for host, service, or service,host pair\n"
        $stderr.write "                     reap: reaps zombie nagios plugin processes\n"
        $stderr.write "             <args>: notification: prints the status of notifications (system-wide)\n"
        $stderr.write "                     notification disabled: prints status of service,host pairs notifications\n"
      end

      def output_options(exit_status)

        puts "Options:\n"

        @options.marshal_dump.each do |name, val|
          puts "  #{name} = #{val}"
        end
        exit exit_status
      end

      def start
        if RbConfig::CONFIG['host_os'] =~ /solaris/i then
          pstatus = popen4("svcadm enable -s #{@options.fmri}") do |pid, pstdin, pstdout, pstderr|
            out = pstdout.readlines.map { |l| l.strip }
            err = pstderr.readlines.map { |l| l.strip }
          end
          raise NagixError, "#{err}" unless pstatus.exitstatus == 0
        end
      end

      def stop
        if RbConfig::CONFIG['host_os'] =~ /solaris/i then
          pstatus = popen4("svcadm disable #{@options.fmri}") do |pid, pstdin, pstdout, pstderr|
            out = pstdout.readlines.map { |l| l.strip }
            err = pstderr.readlines.map { |l| l.strip }
          end
          raise NagixError, "#{err}" unless pstatus.exitstatus == 0
        end
      end

      def pid
        @lql = Nagix::MKLivestatus.new(:socket => settings.mklivestatus_socket,
                                       :log_file => settings.mklivestatus_log_file,
                                       :log_level => settings.mklivestatus_log_level)
        @lql.find(:status, :column => "nagios_pid")
      end

      def reap
        if RbConfig::CONFIG['host_os'] =~ /solaris/i then
          pstatus = popen4("ps -eo pid,user,args | egrep 'nagios.*defunct' | egrep -v 'grep' | awk '{print $1}' | xargs -n1 preap") do |pid, pstdin, pstdout, pstderr|
            out = pstdout.readlines.map { |l| l.strip }
            err = pstderr.readlines.map { |l| l.strip }
          end
          raise NagixError, "#{err}" unless pstatus.exitstatus == 0
        end
      end

      def reload
        nagios_pid = pid
        pstatus = popen4("kill -HUP pid") do |pid, pstdin, pstdout, pstderr|
            out = pstdout.readlines.map { |l| l.strip }
            err = pstderr.readlines.map { |l| l.strip }
          end
          raise NagixError, "#{err}" unless pstatus.exitstatus == 0
      end

      def find(argument)
        MKLivestatus.find(:hosts,'host_name','host_name')
        MKLivestatus.find(:services,'service_description','service_description')
        MKLivestatus.find(:servicegroups,'name','name')
      end
  end
end
