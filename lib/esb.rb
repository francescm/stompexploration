require 'stomp'
require 'sekrets'
#require 'logger'

class Esb

  def initialize

    config = Sekrets.settings_for('./config/settings.yml.enc')[:esb]
    @user = config[:user]
    @pass = config[:pass]
    @host = "localhost"
    @port = 61_613
    @publish = "/queue/" + config[:publish]
    @subscribe = "/queue/" + config[:subscribe]
    $LOGGER.info("Esb destination: %p" % @publish)
  end

  def publish msg
    client = Stomp::Client.new config_hash
    headers = {suppress_content_length: true, persistent: true}
    client.publish @publish, msg, headers
    $LOGGER.info("published to esb %p" % msg) if $LOGGER
    client.close
  end

  def subscribe
    client = Stomp::Client.new(config_hash)
    uuid = client.uuid
    $LOGGER.info("uuid: %p" % uuid) if $LOGGER
    protocol = client.protocol
    $LOGGER.info("protocol: %p" % protocol) if $LOGGER
    $LOGGER.debug("Connected: %p" % client.connection_frame ) if $LOGGER
    headers = sub_headers protocol

    client.subscribe(@subscribe, headers) do |msg|
      begin

        $LOGGER.debug("Msg: %p" % msg) if $LOGGER
        yield msg
        raise "Should exit"
        client.acknowledge(msg)
        $LOGGER.debug("Ack done maybe") if $LOGGER

      rescue Exception => e
        client.nack msg
        $LOGGER.error("Exception: %p" % e.message) if $LOGGER
        client.close
        $LOGGER.info("Client disconnect complete") if $LOGGER
      end
    end
    client.join
  end

  def shovel
    client = Stomp::Client.new(config_hash)
    uuid = client.uuid
    $LOGGER.info("uuid: %p" % uuid) if $LOGGER
    protocol = client.protocol
    $LOGGER.info("protocol: %p" % protocol) if $LOGGER
    $LOGGER.debug("Connected: %p" % client.connection_frame ) if $LOGGER
    headers = sub_headers protocol
      client.subscribe(@subscribe, headers) do |msg|
        tx = "tx-#{random_id}"
        client.begin(tx)
        yield client, msg, tx
        client.acknowledge(msg, transaction: tx)
        client.commit tx
      rescue Exception => e
        client.nack(msg)
        client.abort tx
        $LOGGER.error("Exception: %p" % e.message) if $LOGGER
        client.close
        $LOGGER.info("Client disconnect complete") if $LOGGER
      end
      client.join


  end

  def inspect
    "Esb on #{@host}:{@port} user: #{@user}"
  end

  private

  def sub_headers(protocol)
    case protocol
    when Stomp::SPL_10
      {ack: "client"}
    else
      {ack: "client-individual", id: random_id, "activemq.prefetchSize" => "1"}
    end
  end

  def config_hash
    {
        hosts: [
            {
                login: @user,
                passcode: @pass,
                host: @host,
                port: @port,
                ssl: false
            }
        ],
        connect_headers: {"accept-version" => "1.1,1.2",
        "host" => `hostname -f`.strip}
    }
  end

  def random_id
    #(0...12).map{(('0'..'9').to_a + ('a'..'z').to_a)[rand(35)]}.join
    (0...12).map{(('0'..'9').to_a)[rand(10)]}.join
  end
end
