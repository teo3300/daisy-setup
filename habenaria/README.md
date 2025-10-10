# Instructions for server setup: `habenaria`

## Initial setup

No specific procedure on the initial setup, just remember to install some packages during setup as it becomes harder to install them later: e.g: `networkmanager`

## Networking

### Static IP

I'm using networkmanager because I am lazy. According to [this blog](https://michlstechblog.info/blog/linux-set-a-static-fixed-ip-with-network-manager-cli/) static IP address can be requested via NetworkManager

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

- Copy both the `.service` and `.timer` file in `/etc/systemd/system`
- Create a file `~/dns/secrets_domain` containing the domais to update
- Create a file `~/dns/secrets_password`containing your dns pasword for authentication
- **Remember to make these file not readable from other users** (`600` permissions)

> Start the service

> ```sh
> systemctl enable --now dnsupdate.service
> ```

> Manually run DNS update, **NOTE**: remember to update \<username\> in the `config`

> ```sh
> ./dnsup config
> ```

**Remember:** you have to manually create the * and @ recofd the first time, the script can only update them, otherwise it will return an error

### Wireguard interface creation

> Create a `config` file in the local wireguard directory, setting the variables. Add executable privileges to the owner (better if setting `700` permissions)
```sh
#!/bin/sh
export SERVER_DOMAIN=<myDomain>
export SERVER_PORT=<myPort>
```

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

`docker-compose.yml` accepts environment variables, here used to separate secrets from the config, all secrets will be written in a file `~/.env` so that doker compose can find them.

> Create a `.env`

> ```sh
> touch .env
> chmod 700 .env
> ```

> Add a specific variable name with a random key

> ```sh
> ./doker/addkey <VARIABLE_NAME> # will simply write `export VARIABLE_NAME=<random>` to .env
> ```

## Services setup

- Services are all in a single docker-compose, alternative service can be started separately
- ~~`nginx`~~ `traefik` reverse proxy to manage certificates and connections
- `bitwarden` password manager
- `pihole` local DNS and DNS blocking
- `jellyfin` media server
- `nextcloud` drive
- `navidrome` music server
etc...

> Start docker, better if from a tmux session

> ```sh
> tmux
> docker compose up
> ```

To more easily work with tmux and avoid conflict with client-server prefixes handling, tmux config file sets `C-Space` as the prefix

## Docker profiles

To make it easier to manage different groups of container, I used differnt profiles, may add or remove some later if needed

- **network**: Networking purpose, such as traefk for referse proxy and pihole for DNS
- **core**: Essential functionalities such (bitwarden, nestloud, gitea, etc.), (includes networking services)
- **servie**: All services aside from networking plus other that I don't always need running
- **intensive**: Services which are resource-intensive (jellyfin which requires GPU acceleration, nextcloud, etc.)

> Start all containers with `<profile>`

> ```sh
> docker compose --profile <profile> up -d
> ```

All docker compose commands can specify a profile, so `down` also allows to turn off specific groups of container

### Additional configuration

> attach a shell to a running container to edit it

> ```sh
> docker exec -it <container> sh
> ```

- `pihole` password can be changed once the container already started, follow the instructions on the admin page
- Disable `traefik` dashboard once you are sure everything is working fine

## Traefik config

~~Copy the traefik config folder in `~/docker` when you update it~~

Traefik config resides outside docker directory, so every modification to original `traefik.yml` or `dynamic.yml` influences traefik instantly

- From `docker-compose.yml`:

  - Expose needed ports and bind volumes, everything should already be in the compose already
  - Remember to bind services to expose to the `frontend` network

- From `traefik/traefik.yml`

  - Disable dashboard once everything is working properly

- From `traefik/dynamic.yml`

  - add `routers` and `services` entry for each new service created, specifying what rules to follow for route match, certificate provider and destination container:port

# More setups

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

## Jellyfin hw acceleration

To have hardware acceleration, depending on the used GPU follow the instruction on [jellyfin's website](https://jellyfin.org/docs/general/administration/hardware-acceleration/nvidia/#configure-with-linux-virtualization) and remember to install `nvidia` drivers and `nvidia-smi`

## Pacman multithread (when running on arch)

> Edit `/etc/pacman.conf` to include 

```conf
ParallelDownloads = 5
```

Then restart the containers

## Synapse config

> Add config lines to `homeserver.yaml` in config directory of synapse 

```yaml
# Should be already set
server_name: "chat.kantai.online"
trusted_key_servers:
  - server_name: "chat.kantai.online"

To manage server in an EZ way: [Admin interface](https://awesome-technologies.github.io/synapse-admin/#/users), [repo](https://github.com/Awesome-Technologies/synapse-admin)

# To use external DB rather than sqlite
database:
  name: <name>
  args:
    user: synapse_user
    password: <generate strong pw>
    dbname: synapse
    host: synapse-db
    cp_min: 5
    cp_max: 10

# Enable registration for new users, I am lazy and don't want to implement funny stuff for login
# Instead I create tokens from the admin page and give them for registration
enable_registration: true
registration_requires_token: true
serve_server_wellknown: true
public_baseurl: "https://chat.kantai.online"
```

## Copyparty config

Default config used for copyparty, copy content in

`docker/copyparty/config/initcfg`

```conf
[global]
  e2dsa, e2ts, dedup, z
  shr: /shr

[accounts]
  <username>: <password>

[/]
  /w
  accs:
    rwmda: <username>

[/broadcast]
  /w/broadcast
  accs:
    rwmda: <username>
    r: *

[/share]
  /w/share
  accs:
    rwmda: <username>
    g: *
  flags:
    fk
```

## ADD:

- syncthing setup remote gui for server
  - syncthing cli config gui raw-address set <VPN_IP>:<SYNCTHING_PORT>
  - setup password from gui
  - OPTIONAL: just put syncthing behind traefik in docker container (core)
