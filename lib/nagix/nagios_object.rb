require 'nagix/mk_livestatus'

module Nagix

  class NagiosObject

    def method_missing
    end

    class Host

      def initialize(name,attributes=nil)
        @name = name
        @services = []
        attributes.keys.sort.each do |attribute|
          case attribute
            when "services"
              attributes[attribute].split(',').each do |s|
                n_service = MKLivestatus.new("/local/var/run/nagios/rw/nagios.lql").find(:services, :filter => "servicedescription=#{s}")
                @services.push(n_service) if n_service
              end
            end

          end

        end

      end

    end

    class Hostgroup

      def initialize(hostgroup_name,attributes)

      end

    end

    class Service

      def initialize(name,host_name,attributes)

      end

      def find

      end

    end

    class Servicegroup

      def initialize(servicegroup_name,attributes)

      end

    end

    class Contact

      def initialize(contact_name,attributes)

      end

    end

    class Contactgroup

      def initialize(contactgroup_name,attributes)

      end

    end

    class Command

      def initialize(command_name,attributes)

      end

    end

    class Timeperiod

      def initialize(timeperiod_name,attributes)

      end

    end
end

