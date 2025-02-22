# Instructions for server setup: `habenaria`

## Initial setup

No specific procedure on the initial setup, just remember to install some packages douring setup as it becomes harder to install them later: e.g: `networkmanager`

## Networking

### Static IP

I'm using networkmanager because I am lazy. According to [this blog](https://michlstechblog.info/blog/linux-set-a-static-fixed-ip-with-network-manager-cli/) static IP address can be requested via NetworkManager via

> Seutp static ip address for a specific connection using NetworkManager

> ```sh
> nmcli con mod "Wired connection 1"        \
>   ipv4.addresses  "<host_addr>/<mask>"    \
>   ipv4.gateway    "<gateway_addr>"        \
>   ipv4.dns        "<dns_addre>"           \
>   ipv4.dns-search "myDomain.org"          \
>   ipv4.method     "manual"
> ```

### DNS records update

`dnsupdate.service` and `dnupdate.timer`, located in `~archived`, provide a timer to update dns records according to the script inside the `dns` folder using [dynamicdns.park-your-domain.com](https://dynamicdns.park-your-domain.com)

- Copy both the `.service` and `.timer` file in `/et/systemd/system`
- Create a file `~/dns/secrets_domain` containing the domais to update
- Create a file `~/dns/secrets_password`containing your dns pasword for authentication
- **Remember to make these file not readable from other users** (`600` permissions)

> Start the service

> ```sh
> systemctl enable --now dnsupdate.service
> ```

> Manually run DNS update

> ```sh
> ./dnsup config
> ```

**Remember:** you have to manually create the * and @ recofd the first time, the script can only update them, otherwise it will return an error

### Wireguard interface creation

Create a `config` file in the local wireguard directory, setting the variables

- `export SERVER_DOMAIN=<myDomain>`
- `export SERVER_PORT=<myPort>` And add executable privileges to the owner (better if setting `700` permissions)

Generate wireguard interface configurations using

> Create the server config interface

> ```sh
> ./setup_server
> ```

> Create the config for each client

> ```sh
> ./setup_client <hostname> <index_in_the_subnet>
> ```

> You can share confogs using QRs

> ```sh
> qrencode -t ANSI -r /etc/wireguard/<hostname>.conf
> ```

don't send your keys around the internet

### NAT and firewall

The specific router used has WebUI running on `:80` and `:443` for local `http` and remote `https` configuration, usually move local configuration to `:8080` and disable remote configuration `https` **BUT** my router still reserve `:443` even if remote configuration is disabled, so move it to another port in order to expose `:443`

Open specific ports:

port                | dest                            | protocol | service
------------------- | ------------------------------- | -------- | -----------------
`:80`               | `<server_addr>:80`              | TCP      | certbot
`:443`              | `<server_addr>:443`             | TCP      | traefik websecure
`:<global_wg_port>` | `<server_addr>:<local_wg_port>` | UDP      | wireguard

## Docker Setup

### Services key generation

`docker-compose.yml` accepts environment variables, here used to separate secrets from the config, all secrets will be written in a file `~/docker/keys`, is this unsafe? Who knows.

> Create a key file in ~/docker/

> ```sh
> cd ~/docker
> touch keys
> chmod 700 keys
> ```

> Add a specific variable name with a random key

> ```sh
> ./addkey <VARIABLE_NAME> # will simply write `export VARIABLE_NAME=<random>` to ./docker/keys
> ```

Remember to `source ~/docker/keys` before starting containers, otherwise you will get an error of missing variables

## Services setup

- Services are all in a single docker-compose, alternative service can be started separately
- ~~`nginx`~~ `traefik` reverse proxy to manage certificates and connections
- `bitwarden` password manager
- `pihole` local DNS and DNS blocking
- `jellyfin` media serve

> Source the key file and start docker, better if from a tmux session

> ```sh
> tmux
> source docker/keys
> docker compose up
> ```

### Additional configuration

> attach a shell to a running container to edit it

> ```sh
> docker exec -it <container> sh
> ```

- `pihole` password can be changed once the container already started, follow the instructions on the admin page
- Disable `traefik` dashboard once you are sure everything is working fine

## Traefik config

> Copy the traefik config folder in `~/docker` when you update it

> ```sh
> sudo cp traefik docker
> ```

- From `docker-compose.yml`:

  - Expose needed ports and bind volumes, everything should already be in the compose already
  - Remember to bind services to expose to the `frontend` network

- From `traefik.yml`

  - Disable dashboard once everything is working properly

- From `dynamic.yml`

  - add `routers` and `services` entry for each new service created, specifying what rules to follow for route match, certificate provider and destination container:port

# More setups, not used now

## Proxy setup for nextcloud

Nextcloud notices being behind a reverse proxy, to prevent annoying warnings configure nextcloud to recognise this proxy as trusted

Edit `nextcloud/nextcloud/config/config.php` with the following changes

```php
// ...

// set https instead of http for URL generation
'overwrite.cli.url' => 'https://<domain>',

// set this mashine as a trusted proxy
'trusted_proxies' => ['<Machine IP>'],

// overwrite protocol
'overwriteprotocol' => 'https',

// ...
```

Then restart the containers
