ARG RUBY_IMAGE=ruby:4.0.4-alpine3.23

FROM ${RUBY_IMAGE} AS builder

WORKDIR "/relay"
COPY Gemfile Gemfile.lock /relay/

ENV BUNDLE_DEPLOYMENT=1
ENV BUNDLE_PATH=/relay/vendor/bundle
RUN bundle install

COPY lib/* /relay

FROM dhi.io/${RUBY_IMAGE}

ENV GEM_HOME=/relay/vendor/bundle/ruby/4.0.0
ENV GEM_PATH=/relay/vendor/bundle/ruby/4.0.0

LABEL org.opencontainers.image.authors="Benjamin Bock <bb-docker-images@bock.be>"
LABEL org.opencontainers.image.licenses="MIT"

EXPOSE 2525

WORKDIR "/relay"
COPY --from=builder /relay /relay

CMD ["ruby", "-w", "/relay/action_mailbox_relay.rb"]

