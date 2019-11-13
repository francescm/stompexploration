#Stomp Exploration

I realized I don't know enought about this protocol I have been 
using since a while without understanding it throughtfully.

## Debugging on activemq

In case you want to debug Stomp communication between broker 
and clients you should configure the Stomp connector with the trace parameter, like this:

    <transportConnectors>
      <transportConnector name="stomp" uri="stomp://localhost:61613?trace=true"/>
    </transportConnectors>

This will instruct the broker to trace all packets it sends 
and receives.

Furthermore, you have to enable tracing for the appropriate log. 
You can achieve that by adding the following to your 
conf/log4j.properties

    log4j.logger.org.apache.activemq.transport.stomp=TRACE

Finally, you will probably want to keep these messages in the 
separate file instead of polluting the standard broker’s log. 
You can achieve that with the following log4j configuration:

    log4j.appender.stomp=org.apache.log4j.RollingFileAppender
    log4j.appender.stomp.file=${activemq.base}/data/stomp.log
    log4j.appender.stomp.maxFileSize=1024KB
    log4j.appender.stomp.maxBackupIndex=5
    log4j.appender.stomp.append=true
    log4j.appender.stomp.layout=org.apache.log4j.PatternLayout
    log4j.appender.stomp.layout.ConversionPattern=%d \[%-15.15t\] %-5p %-30.30c{1} - %m%n
    
    log4j.logger.org.apache.activemq.transport.stomp=TRACE, stomp
    log4j.additivity.org.apache.activemq.transport.stomp=false
    
    # Enable these two lines and disable the above two if you want the frame IO ONLY (e.g., no heart beat messages, inactivity monitor etc).
    #log4j.logger.org.apache.activemq.transport.stomp.StompIO=TRACE, stomp
    #log4j.additivity.org.apache.activemq.transport.stomp.StompIO=false

After this, all your Stomp packets will be logged to the data/stomp.log

## Negotiate protocol level

You need to send a custom connection-header hash including:
- accept-version
- host
example:

      connect_headers: {"accept-version" => "1.1,1.2",
        "host" => `hostname -f`.strip}


## Subscription with ack client

First note there is a difference between STOMP1.0 and versions 1.1 
or higher:

- STOMP_1.0 has only ack: client
- STOMP_1.1 has also ack: client-individual

The ack cmd is also different, but the `client.ack(msg)` call 
takes care of the differences.

## nack

On Activemq `nack` means: move msg to DLQ.

But to have something sensible, msg have to be persistent 
(non-persistent msg are simply discarded) and you'd better 
add a `individualDeadLetterStrategy`. Without it all messages 
would add together in a single queue and mess things up.

 

