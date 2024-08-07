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
      logger.debug("mail received at: [#{ctx[:server][:local_ip]}:#{ctx[:server][:local_port]}] from: #{ctx[:envelope][:from]} for recipient(s): #{ctx[:envelope][:to]}...")


      raw_email = ctx[:message][:data]
      ctx[:envelope][:to].reverse.each do |to|
        raw_email.prepend("X-Original-To: ", to, "\n")
      end

      ActionMailbox::Relayer.new(url: url, password: ingress_password).relay(raw_email).tap do |result|
        logger.info("Mail from: #{ctx[:envelope][:from]} for recipient(s): #{ctx[:envelope][:to]}")

        case
        when result.success?
          logger.debug("SUCCESS: #{result.message}")
        when result.transient_failure?
          logger.warn("TRANSIENT FAILURE: #{result.message}")
        else
          logger.error("UNKNOWN FAILURE: #{result.message}")
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
    $stdout.sync = true

    url, password = ENV.values_at("URL", "INGRESS_PASSWORD")

    if !url || url.length == 0
      puts "URL is required"
      exit 111
    end
    if !password || password.length == 0
      puts "INGRESS_PASSWORD is required"
      exit 112
    end

    hosts = ENV.fetch("HOSTS", "0.0.0.0")
    ports = ENV.fetch("PORTS", "2525")
    logger_severity = Logger::SEV_LABEL.index ENV.fetch("LOG_LEVEL", "WARN").upcase # WARN if not present, DEBUG if wrong/unkown

    server = ActionMailboxDockerRelay::Server.new hosts: hosts, ports: ports, logger_severity: logger_severity
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
    server.logger.warn("Starting ActionMailboxDockerRelayServer [based on MidiSmtpServer #{MidiSmtpServer::VERSION::STRING}|#{MidiSmtpServer::VERSION::DATE}] relaying to #{url}")

    # setup exit code
    at_exit do
      # check to shutdown connection
      if server
        # Output for debug
        server.logger.warn('Ctrl-C interrupted, exit now...') if flag_status_ctrl_c_pressed
        # info about shutdown
        server.logger.info('Shutdown ActionMailboxDockerRelayServer...')
        # stop all threads and connections gracefully
        server.stop
      end
      # Output for debug
      server.logger.warn('ActionMailboxDockerRelayServer down!')
    end

    # Start the server
    server.start

    # Run on server forever
    server.join
  end

  main if __FILE__ == $0
end

