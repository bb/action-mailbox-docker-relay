FROM ruby:3.2.2-alpine

LABEL org.opencontainers.image.authors="Benjamin Bock <bb-docker-images@bock.be>"
LABEL org.opencontainers.image.licenses="MIT"

EXPOSE 2525

WORKDIR "/relay"
COPY Gemfile Gemfile.lock /relay

RUN bundle

COPY lib/* /relay

CMD ["./action_mailbox_relay.rb"]
