class RabbitCourier::RPCClient
  DEFAULT_QUEUE_OPTS = {exclusive: false, auto_delete: false}

  attr_accessor :correlation_id, :response
  attr_reader :lock, :condition

  def initialize(name, opts = {})
    @name = name
    @reply_queue = channel.queue(reply_queue_name(name), DEFAULT_QUEUE_OPTS.merge(opts))

    @lock = Mutex.new
    @condition = ConditionVariable.new
  end

  def call(message, correlation_id)
    self.correlation_id = correlation_id

    consumer = subscribe_to_reply
    exchange.publish(message.to_s, routing_key: @name, reply_to: @reply_queue.name, correlation_id: correlation_id)

    # wait for condition
    lock.synchronize { condition.wait(lock) }
    consumer.cancel

    response
  end

  private

  def subscribe_to_reply
    myself = self
    @reply_queue.subscribe do |delivery_info, properties, payload|
      if properties[:correlation_id] == myself.correlation_id.to_s
        myself.response = payload

        # signal the condition
        myself.lock.synchronize { myself.condition.signal }
      end
    end
  end

  def channel
    @channel ||= RabbitCourier.connection.create_channel
  end

  def exchange
    @exchange ||= channel.default_exchange
  end

  def reply_queue_name(name)
    name + ".reply"
  end
end
