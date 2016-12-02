require "courier/version"
require "courier/rpc_client"
require "bunny"

module Courier
  def self.connection
    @connection ||= Bunny.new(recover_from_connection_close: false).tap(&:start)
  end

  def self.new(name, opts = {})
    Courier::RPCClient.new(name, opts)
  end
end
