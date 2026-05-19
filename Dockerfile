FROM ruby:4.0.4-alpine

LABEL org.opencontainers.image.authors="Benjamin Bock <bb-docker-images@bock.be>"
LABEL org.opencontainers.image.licenses="MIT"

EXPOSE 2525

WORKDIR "/relay"
COPY Gemfile Gemfile.lock /relay/

RUN apk upgrade --no-cache && \
    gem update --system && \
	gem uninstall -i /usr/local/lib/ruby/gems/4.0.0 net-imap bigdecimal && \
	gem cleanup && \
	bundle config set deployment 'true' && \
	bundle install

COPY lib/* /relay

CMD ["bundle", "exec", "ruby", "-w", "./action_mailbox_relay.rb"]
