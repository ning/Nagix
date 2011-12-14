module Nagix

  class NagiosXcmd

    NAGIOSXCMDS = {
      :DISABLE_NOTIFICATIONS =>                     { :signature => "" , :command_id => 7 },
      :ENABLE_NOTIFICATIONS =>                      { :signature => "", :command_id => 8 },
      :DISABLE_SVC_NOTIFICATIONS =>                 { :signature => "host_name;service_description", :command_id => 12 },
      :ENABLE_SVC_NOTIFICATIONS =>                  { :signature => "host_name;service_description", :command_id => 11 },
      :DISABLE_SERVICEGROUP_HOST_NOTIFICATIONS =>   { :signature => "servicegroup", :command_id => 94 },
      :ENABLE_SERVICEGROUP_HOST_NOTIFICATIONS =>    { :signature => "servicegroup", :command_id => 93 },
      :DISABLE_SERVICEGROUP_SVC_NOTIFICATIONS =>    { :signature => "servicegroup", :command_id => 92 },
      :ENABLE_SERVICEGROUP_SVC_NOTIFICATIONS =>     { :signature => "servicegroup", :command_id => 91 },
      :ENABLE_HOSTGROUP_HOST_NOTIFICATIONS =>       { :signature => "hostgroup", :command_id => 81 },
      :ACKNOWLEDGE_HOST_PROBLEM =>                  { :signature => "<host_name>;<sticky>;<notify>;<persistent>;<author>;<comment>", :command_id => 39 },
      :ACKNOWLEDGE_SVC_PROBLEM =>                   { :signature => "<host_name>;<service_description>;<sticky>;<notify>;<persistent>;<author>;<comment>", :command_id => 40 }
    }

    def self.docurl(napixcmd)
      NAGIOSXCMDS.has_key?(napixcmd.to_sym) ? "http://old.nagios.org/developerinfo/externalcommands/commandinfo.php?command_id=#{NAGIOSXCMDS[napixcmd.to_sym][:command_id]}" : nil
    end

    class Error < StandardError; end
    class MissingParameters < Error; end

    def initialize(napixcmd,params)
      @napixcmd = napixcmd.to_sym
      @cmd = nil
      if NAGIOSXCMDS.has_key?(@napixcmd)
        @cmd = napixcmd
        NAGIOSXCMDS[@napixcmd][:signature].split(';').each do |p|
          raise MissingParameters, "Missing parameter #{p} for Nagios External Command #{@napixcmd}; see #{NagiosXcmd.docurl(@napixcmd)}" if params[p.to_sym] == nil
          @cmd += ";#{params[p.to_sym]}"
        end
      end
    end

    def to_s
      @cmd
    end

  end
end

