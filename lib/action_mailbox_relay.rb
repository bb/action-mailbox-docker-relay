#!/usr/bin/env ruby
# frozen_string_literal: true

# based on https://github.com/4commerce-technologies-AG/midi-smtp-server/blob/master/examples/midi-smtp-server-example.rb

require 'midi-smtp-server'
require_relative 'mini_action_mailbox_relayer'

module ActionMailboxDockerRelay
# Server class
  class Server < MidiSmtpServer::Smtpd

    attr_accessor :url, :ingress_password

    # get each message after DATA <message> .
    def on_message_data_event(ctx)
      # Output for debug
      logger.debug("mail received at: [#{ctx[:server][:local_ip]}:#{ctx[:server][:local_port]}] from: [#{ctx[:envelope][:from]}] for recipient(s): [#{ctx[:envelope][:to]}]...")


      raw_email = ctx[:message][:data]
      raw_email.prepend("X-Original-To: ", ctx[:envelope][:to], "\n")
      # raw_email.prepend("X-Envelope-To: ", ctx[:envelope][:to], "\n")
      # raw_email.prepend("X-Original-From: ", ctx[:envelope][:from], "\n")
      # raw_email.prepend("X-Envelope-From: ", ctx[:envelope][:from], "\n")

      ActionMailbox::Relayer.new(url: url, password: ingress_password).relay(raw_email).tap do |result|
        print result.message

        case
        when result.success?
          logger.debug("SUCCESS")
        when result.transient_failure?
          logger.debug("TRANSIENT FAILURE")
        else
          logger.debug("UNKNOWN FAILURE")
        end
      end
    end

    def on_logging_event(_ctx, severity, msg, err: nil)
      super
      if err
        @logger_protected.error(err.inspect)
        @logger_protected.error(err)
      end
    end
  end

  def self.main
    url, password = ENV.values_at("URL", "INGRESS_PASSWORD")

    if !url || url.length == 0
      print "URL is required"
      exit 111
    end
    if !password || password.length == 0
      print "INGRESS_PASSWORD is required"
      exit 112
    end

    hosts = ENV.fetch("HOSTS", "0.0.0.0")
    ports = ENV.fetch("PORTS", "2525")

    server = ActionMailboxDockerRelay::Server.new hosts: hosts, ports: ports
    server.url = url
    server.ingress_password = password


    # save flag for Ctrl-C pressed
    flag_status_ctrl_c_pressed = false

    # try to gracefully shutdown on Ctrl-C
    trap('INT') do
      # print an empty line right after ^C
      puts
      # notify flag about Ctrl-C was pressed
      flag_status_ctrl_c_pressed = true
      # signal exit to app
      exit 0
    end

    # Output for debug
    server.logger.info("Starting ActionMailboxDockerRelayServer [based on MidiSmtpServer #{MidiSmtpServer::VERSION::STRING}|#{MidiSmtpServer::VERSION::DATE}]")

    # setup exit code
    at_exit do
      # check to shutdown connection
      if server
        # Output for debug
        server.logger.info('Ctrl-C interrupted, exit now...') if flag_status_ctrl_c_pressed
        # info about shutdown
        server.logger.info('Shutdown ActionMailboxDockerRelayServer...')
        # stop all threads and connections gracefully
        server.stop
      end
      # Output for debug
      server.logger.info('MySmtpd down!')
    end

    # Start the server
    server.start

    # Run on server forever
    server.join
  end

  main if __FILE__ == $0
end

