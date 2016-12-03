require "rabbit_courier/version"
require "rabbit_courier/rpc_client"
require "bunny"

module RabbitCourier
  def self.connection
    @connection ||= Bunny.new(recover_from_connection_close: false).tap(&:start)
  end

  def self.new(name, opts = {})
    RabbitCourier::RPCClient.new(name, opts)
  end
end
