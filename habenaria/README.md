# Instructions for server setup: `habenaria`

## Initial setup

All scripts are run with `zsh` in mind, some only need minor changes to run with bash (remove `${(s: :)VAR}` for list split)

No specific procedure on the initial setup, just remember to install some packages during setup as it becomes harder to install them later: e.g: `networkmanager`

To boot headless from serial port after ArchISO installation specify (assuming grub):
```cfg
GRUB_CMDLINE_LINUX_DEFAULT="... console=tty0 console=ttyS0,115200 ..."
```

## Configuration and environment

All commands are configured by setting environment variables in `~/.env`, when a command fails requiring a variable or warns you about a missing variable definition, try checking the content of this file

## Task shceduling

Despite systemd timer existing, I find much easier to work with crontab, all tasks that need to be scheduled will be run using crontab, install a crontab manager (e.g.: `cronie`) if your distro does not provide one, edit the crontab config at `~/crontab` and load it

> Load the crontab config

> ```sh
> crontab ~/crontab
> ```

Some managers require you to manually enable the daemon (???: the wiki says so for cronie but it was working out of the box after the config load)

> Manually start the daemon

> ```sh
> systemctl enable --now <crontabmanager>.service # e.g.: cronie.service
> ```

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

Dns update scheduling is done with crontab, install a crontab manager if your distro doesn't have one already, edit the `crontab` file and reload it (as for certificates renewal) 

> You can also manually run DNS update

> ```sh
> # ~/dnsup/<DNS>.sh
> 
> # Namecheap
> zsh ~/dnsup/namecheap.sh
> # Or, if you are using Dynu:
> zsh ~/dnsup/dynu.sh
> ```

**Remember:** For some services, like namecheap, you have to manually create the * and @ records, the script can only update them, otherwise it will return an error

### Wireguard interface creation

> Create a `config` file in the local wireguard directory, setting the variables. Add executable privileges to the owner (better if setting `700` permissions)

<!-- TODO: reduce the critical section within sudo, load venv and then sudo to copy files -->

```sh
#!/bin/sh
# This is set independently from environment as these scripts will be run under
#   superuser (they need to write in "/etc")
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
`:443`              | `<server_addr>:443`             | TCP      | reverse-proxy websecure
`:<global_wg_port>` | `<server_addr>:<local_wg_port>` | UDP      | wireguard

## Docker Setup

### Services key generation

`docker-compose.yml` accepts environment variables, here used to separate secrets from the config, all secrets will be written in a file `~/.env` so that doker compose can find them.

> Create a `.env`

> ```sh
> touch .env
> chmod 600 .env
> ```

> Add a specific variable name with a random key

> ```sh
> ./doker/addkey <VARIABLE_NAME> # will simply write `export VARIABLE_NAME=<random>` to .env
> ```

## Services setup

- Services are all in a single docker-compose, alternative services can be started separately
- `nginx` as a reverse proxy to manage certificates and connections
- `bitwarden` password manager
- `pihole` local DNS and DNS blocking
- `jellyfin` media server
- `nextcloud` drive
- `navidrome` music server
etc...

> Start docker, using `--profile` is possible to start a specific profile (set of containers), multiple profiles can be selected by adding another `--profile` param, specific containers can be started by name

> ```sh
> # tmux
> docker compose [--profile <profile> ...] up -d <container> [container ...]
> # docker compose up # <- this would leave the terminal attached, check the logs instead
> ```

## traefik

The default reverse proxy is now nginx, traefik config files kept to be able to switch in the future

## nginx
### New certificates

> REMEMBER: you have to provide variables `SERVER_DOMAINS` and `CERTBOT_EMAIL` to the compose or manually set them (I use `~/.env`)

To make all new certificates in bulk, stop any service running behind port:80 and run `makecerts` (this will already stop `nginx` container if running and start it again), be sure to export the variables `$SERVER_DOMAIN` and `$SERVER_SUBDOMAINS`, to emit certificates for all subdomains
```sh
zsh ~/makecerts
```

Certificate creation is done by running a limited-config nginx container `nginx-certbot` which only serves certbot challenges, and the `certbot-new` container, which requires new certificates.

To add new domains simply run the script again

### Certificates renewal

Certificate renewal is attempted once a month via crontab by using `certbot` container when the the default `nginx` container is running

### Config file template

Nginx config is a template file from which the actual config is generated, make sure to have executable permissions for `~/nginx/makeconf.sh` which substitute environment variables.

To use an environment variable pass it to the container and add it to the `envsubst`'s list of substution in makeconf.sh

## Tmux prefix change

To more easily work with tmux and avoid conflict with client-server prefixes handling, tmux config file sets `C-Space` as the prefix

## Docker profiles

To make it easier to manage different groups of container, I used differnt profiles, may add or remove some later if needed

- **network**: Networking purpose, such as traefk for referse proxy and pihole for DNS
- **core**: Essential functionalities such (bitwarden, nextloud, pihole, etc.), (includes networking services)
- **service**: All services aside from networking plus other that I don't always need running
- **intensive**: Services which are resource-intensive (jellyfin which requires GPU acceleration, nextcloud, etc.)
- **network-alt**: Alternative networking, using nginx
- **dummy**: Temporary container which are started from scripts for automated processes (like certificates renewal)

> Start all containers in `<profile>`

> ```sh
> docker compose --profile <profile> up -d
> ```

All docker compose commands can specify a profile, so `down` also allows to turn off specific groups of container

### Additional configuration (cheatsheet)

> attach a shell to a running container to edit it

> ```sh
> docker exec -it <container> sh
> ```

- `pihole` password can be changed once the container already started, follow the instructions on the admin page
- Autoredirection from `/` to `/admin` for pihole is set by default after settig `webserver.domain` in `pihole.toml` in the pihole config

## Traefik config (if using traefik networking)

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

Nextcloud detects being behind a reverse proxy, to prevent annoying warnings configure nextcloud to recognise this proxy as trusted.

All these values should be correctly initialized from within the comopse th first time you start nextcloud, only change them if you happen to change domain after the initial nextcloud configuration

> Edit `nextcloud/nextcloud/config/config.php`

```php
// ...

// set https instead of http for URL generation
'overwrite.cli.url' => 'https://<nextcloud_domain>',

// set this mashine as a trusted proxy (can use net masks)
'trusted_proxies' => ['<Machine IP>[/<mask>]'],

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
server_name: "<synapse_domain>"
trusted_key_servers:
  - server_name: "<synapse_domain>"

To manage server in an EZ way: [Admin interface](https://awesome-technologies.github.io/synapse-admin/#/users), [repo](https://github.com/Awesome-Technologies/synapse-admin)

# To use external DB rather than sqlite
database:
  name: <name>
  args:
    user: synapse_user
    password: <generated_strong_pw>
    dbname: synapse
    host: synapse-db
    cp_min: 5
    cp_max: 10

# Enable registration for new users, I am lazy and don't want to implement funny stuff for login
# Instead I create tokens from the admin page and give them for registration
enable_registration: true
registration_requires_token: true
serve_server_wellknown: true
public_baseurl: "https://<synapse_domain>"
```

# Config sync

Copy relevant files to a git repo to save confit (requires to define `GITREPO` in the env to locate the git root)

> Copy the current config from the server to the github repository

> ```sh
> sh gitdump.sh
> ```

---
---

## Additional config I still have to document:

- syncthing setup remote gui for server
  - as daemon:
  - remote gui:  syncthing cli config gui raw-address set <VPN_IP>:<SYNCTHING_PORT>
  - setup password from gui
  - config different base directory: `man syncthing-config` and change the default directory in one of config.xml according to [documentation](https://docs.syncthing.net/users/config.html#defaults-element) (change configuration > defaults > folder.path to something like ~/syncthing)
  - OPTIONAL: just put syncthing behind traefik in docker container (core)

# Power settings

Referencing the [ArchWiki](https://wiki.archlinux.org/title/Power_management#Power_saving) page.

- Disable any wireless device with `rfkill`
- Disable NMI watchdog if affordable
- Use powersaving mode
