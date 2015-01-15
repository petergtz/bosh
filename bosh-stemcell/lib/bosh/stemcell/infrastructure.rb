module Bosh::Stemcell
  module Infrastructure
    def self.for(name)
      case name
        when 'openstack'
          OpenStack.new
        when 'aws'
          Aws.new
        when 'vsphere'
          Vsphere.new
        when 'warden'
          Warden.new
        when 'vcloud'
          Vcloud.new
        when 'null'
          NullInfrastructure.new
        else
          raise ArgumentError.new("invalid infrastructure: #{name}")
      end
    end

    class Base
      attr_reader :name, :hypervisor, :default_disk_size, :disk_formats

      def initialize(options = {})
        @name = options.fetch(:name)
        @supports_light_stemcell = options.fetch(:supports_light_stemcell, false)
        @hypervisor = options.fetch(:hypervisor)
        @default_disk_size = options.fetch(:default_disk_size)
        @disk_formats = options.fetch(:disk_formats)
      end

      def ==(other)
        name == other.name &&
          hypervisor == other.hypervisor &&
          default_disk_size == other.default_disk_size
      end
    end

    class NullInfrastructure < Base
      def initialize
        super(name: 'null', hypervisor: 'null', default_disk_size: -1, disk_formats: [])
      end
    end

    class OpenStack < Base
      def initialize
        super(name: 'openstack', hypervisor: 'kvm', default_disk_size: 3072, disk_formats: ['raw', 'qcow2'])
      end
    end

    class Vsphere < Base
      def initialize
        super(name: 'vsphere', hypervisor: 'esxi', default_disk_size: 3072, disk_formats: ['ovf'])
      end
    end

    class Vcloud < Base
      def initialize
        super(name: 'vcloud', hypervisor: 'esxi', default_disk_size: 3072, disk_formats: ['ovf'])
      end
    end

    class Aws < Base
      def initialize
        super(name: 'aws', hypervisor: 'xen', supports_light_stemcell: true, default_disk_size: 2048, disk_formats: ['raw'])
      end
    end

    class Warden < Base
      def initialize
        super(name: 'warden', hypervisor: 'boshlite', default_disk_size: 2048, disk_formats: []) # todo wha???
      end
    end
  end
end
