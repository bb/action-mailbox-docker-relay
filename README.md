This provides an SMTP Service which posts any e-mail it receives to an HTTP endpoint. The primary use case is for Ruby on Rails' ActionMailbox.

It can be used e.g. as a Transport behind a Relay Domain behind a real mail server like Mailcow. No guarantees are made when used directly on the public internet.
There's no filtering nor authentication... but PRs are welcome.

Source: https://github.com/bb/action-mailbox-docker-relay

Docker Hub: https://hub.docker.com/r/bock/action-mailbox-docker-relay

## Environment

* `INGRESS_PASSWORD` (required): the password which should be used to authenticate to the Rails application. 
* `URL` (required): the URL which the e-mails should be posted to, e.g. `https://example.org/rails/action_mailbox/relay/inbound_emails`.
* `HOSTS` (optional, default: `0.0.0.0`): the host or hosts (comma separated) which the server should bind to.
* `PORTS` (optional, default: `2525`): the port or ports (comma separated) which the server should listen on.
* `LOG_LEVEL` (optional, default: `WARN`, fallback to `DEBUG` if unknown, case-insensitive): see https://rubyapi.org/o/logger
  * ERROR: only failures printed to stdout
  * WARN: messages on startup, shutdown, transient errors
  * INFO: one line per mail processed
  * DEBUG: everything


## Example Docker Compose file

### Essentials

Be sure to change the ingress password!

```yaml
services:
  example-mailbox:
    image: bock/action-mailbox-docker-relay
    environment:
      URL: https://example.org/rails/action_mailbox/relay/inbound_emails
      INGRESS_PASSWORD: secr3t
```

### Using mailcow network

Add it to mailcow under *Admin* -> *Routing* -> *Transport Maps*.
Destination: e.g. `example.org`
Next hop: e.g. `example-mailbox:2525`
Username/Password not needed.

```yaml
services:
  example-mailbox:
    image: bock/action-mailbox-docker-relay
    environment:
      URL: https://example.org/rails/action_mailbox/relay/inbound_emails
      INGRESS_PASSWORD: secr3t
  networks:
    - mailcowdockerized_mailcow-network

networks:
  mailcowdockerized_mailcow-network:
    external: true
```

### Using a template for multiple containers

```yaml
x-base: &base
  image: bock/action-mailbox-docker-relay
  networks:
    - mailcowdockerized_mailcow-network

services:
  example-mailbox:
    <<: *base
    environment:
      URL: https://example.org/rails/action_mailbox/relay/inbound_emails
      INGRESS_PASSWORD: secr3t

  examplecom-mailbox:
    <<: *base
    environment:
      URL: https://www.example.com/rails/action_mailbox/relay/inbound_emails
      INGRESS_PASSWORD: secr3t
      # staging: Passwort sowohl in der Instanz als auch in Caddy basicauth

networks:
  mailcowdockerized_mailcow-network:
    external: true
```


### Public (use at your own risk)

```yaml
services:
  example-mailbox:
    image: bock/action-mailbox-docker-relay
    environment:
      URL: https://example.org/rails/action_mailbox/relay/inbound_emails
      INGRESS_PASSWORD: secr3t
      PORTS: 25
    ports:
      - "0.0.0.0:25:25
```

## Alternative approaches

You *do not* need this, if you use an external email provider which provides webhooks like those described in the [Action Mailer Basics Rails Guide](https://guides.rubyonrails.org/action_mailbox_basics.html) (Mailgun, Mandrill, Postmark, Sendgrid).

You *do not* need this, if you run and configure your own mail server like those described in the [Action Mailer Basics Rails Guide](https://guides.rubyonrails.org/action_mailbox_basics.html) (Exim, Postfix, Qmail).

You do not need this, if you use Amazon SES/SNS. In this case you can use other 3rd party integrations like [action_mailbox_amazon_ingress](https://github.com/bobf/action_mailbox_amazon_ingress).

[Action-mailbox-docker-postfix-relay](https://github.com/Loumaris/action-mailbox-docker-postfix-relay) by Loumaris / Christian Heimke provides roughly the same features, however you *must* build the Docker images yourself as the configuration will be hardcoded. It runs a full Postfix server and contains a minimal Rails app while this project only runs a single Ruby executable which receives the Mail and triggers the webhook. Their Docker image size on disk is ~675 MB while this is <100 MB.

[PostalServer allows receiving e-mail by HTTP](https://docs.postalserver.io/developer/http-payloads), however you'll need a custom Action Mailbox ingress to process their raw message payload.

[mail_room](https://github.com/tpitale/mail_room) gem allows polling IMAP mailboxes, so you could use it with GMail. It also works with Outlook / Hotmail.

