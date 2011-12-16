require 'socket'
require 'log4r'
require 'nagix/nagios_object'

module Nagix

  class MKLivestatus
    # MKLivestatus is a simple class to interact with the MK LiveStatus Nagios socket. It does not
    # fully implement all of its capabilities, but enough for our needs

    class Error < StandardError; end
    class LQLError < Error; end

    def initialize(params)
      # need to create the logger first so it initializes the log levels
      @lqlpath = params[:socket]
      @log = Log4r::Logger.new('lql')
      log_file = params[:log_file] || "nagix.lql.log"
      log_level = Log4r.const_get(params[:log_level] || "WARN")
      @log.add Log4r::FileOutputter.new("logfile",
                                        :filename => log_file,
                                        :trunc => false,
                                        :formatter => Log4r::PatternFormatter.new(:pattern => "[%d] %c [%p] %l %m"),
                                        :level => log_level)
    end

    def self.connect(socketpath)
      @lqlsocket = UNIXSocket.open(socketpath)
    end

    def self.connected?
      @lqlsocket.nil? ? false : true
    end

    def self.disconnect()
      @lqlsocket.close if @lqlsocket.nil?
    end

    def find(table,lqlargs)

      @lqlsocket = MKLivestatus.connect(@lqlpath) if @lqlsocket.nil?

      result = []
      result__ = []

      query = "GET #{table.to_s}\nResponseHeader: fixed16\n"

      filter = ""
      if lqlargs[:filter].nil? then
        filter = nil
      else
        lqlargs[:filter].each do |f|
          f.match(/^Or:|And:/) ? filter += "#{f}\n" : filter += "Filter: #{f}\n"
        end
        filter = nil if filter.size == 0
      end

      @log.debug "FILTER: \n#{filter}"
      query += "#{filter}" unless filter.nil?

      column = lqlargs[:column]
      @log.debug "COLUMN: \n#{column}"
      query += "Columns: #{column}\nColumnHeaders: on\n" unless column.nil?
      query += "\n"

      @log.debug "QUERY: \n#{query}"

      begin
        @lqlsocket.puts(query)
        query_result = @lqlsocket.readlines
        @log.debug "QUERY RESULT:\n#{query_result}\n"

        __header = query_result.shift.chomp
        __columns = query_result.shift.chomp.split(';')

        query_result.each do |line|
          hsh = {}
          columns = Array.new(__columns)
          values = line.chomp.split(';')
          columns.zip(values) { |k,v| hsh[k] = v }
          if table == :hosts then
            @log.debug "#{hsh.class()} #{hsh.inspect()}"
            result__.push(NagiosObject::Host.new(hsh['name'],hsh))
          end
          result.push(hsh)
        end
      rescue
        result = nil
        raise
      end

      @lqlsocket.close
      @lqlsocket = nil

      @log.debug "RETURN RESULT:\n#{result}\n"
      result
    end

    def xcmd(napixcmd)
      @lqlsocket = MKLivestatus.connect(@lqlpath) if @lqlsocket == nil
      command = "COMMAND [#{Time.now.to_i}] #{napixcmd}\n\n"
      @lqlsocket.puts(command)
      @lqlsocket.close
      @lqlsocket = nil
    end
  end
end
