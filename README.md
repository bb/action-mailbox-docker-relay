This provides an SMTP Service which posts any e-mail it receives to an HTTP endpoint. The primary use case is for Ruby on Rails' ActionMailbox.

It can be used e.g. as a Transport behind a Relay Domain behind a real mail server like Mailcow. No guarantees are made when used directly on the public internet.
There's no filtering nor authentication... but PR's are welcome.

Source: https://github.com/bb/action-mailbox-docker-relay

Docker Hub: https://hub.docker.com/r/bock/action-mailbox-docker-relay

## Environment

* `INGRESS_PASSWORD` (required): the password which should be used to authenticate to the Rails application. 
* `URL` (required): the URL which the e-mails should be posted to, e.g. `https://example.org/rails/action_mailbox/relay/inbound_emails`.
* `HOSTS` (optional, default: `0.0.0.0`): the host or hosts (comma separated) which the server should bind to.
* `PORTS` (optional, default: `2525`): the port or ports (comma separated) which the server should listen on.

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