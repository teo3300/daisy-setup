# Instructions for server setup: `habenaria`

## Initial setup

No specific procedure on the initial setup, just remember to install some packages during setup as it becomes harder to install them later: e.g: `networkmanager`

To boot headless from seril port after ArchISO installation specify (assuming grub):
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

> ``sh
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

~~`dnsupdate.service` and `dnupdate.timer`, located in `~archived`, provide a timer to update dns records according to the script inside the `dns` folder using [dynamicdns.park-your-domain.com](https://dynamicdns.park-your-domain.com)~~

Dns update scheduling is now done with crontab, install a crontab manager if your distro doesn't have one already and load the `crontab` file (same pocess as for certificate renewal)

- ~~Copy both the `.service` and `.timer` file in `/etc/systemd/system`~~
- ~~Create a file `~/dns/secrets_domain` containing the domais to update~~
- ~~Create a file `~/dns/secrets_password`containing your dns pasword for authentication~~
- ~~**Remember to make these file not readable from other users** (`600` permissions)~~

> You can also manually run DNS update

> ```sh
> ~/dnsup.sh
> # Or, if you are using Dynu:
> ~/dynup.sh
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
- ~~`nginx reverse proxy`~~ `traefik` to manage certificates and connections
- `bitwarden` password manager
- `pihole` local DNS and DNS blocking
- `jellyfin` media server
- `nextcloud` drive
- `navidrome` music server
etc...

> Start docker, ~~Better if from a tmux session~~, using `--profile` is possible to start a specific profile (set of containers), multiple profiles can be selected by adding another `--profile` param, specific containers can be started by name

> ```sh
> # tmux
> docker compose [--profile <profile>] up -d <container> [container ...]
> # docker compose up # <- this would leave the terminal attached, check the logs instead
> ```

## Use nginx instead of traefik

Shutdown `traefik` and use the container `nginx` instead, still working on this conf so I'm leaving it as optional
> ~~For this to work properly, the very first run must be done disabling the https server in nginx confs
  Otherwise nginx will crash for missing certificates

For the first run, in order to properly obtain the certificates I usually do: 
- comment 443 config in `nginx.conf`
- up `nginx`
- up `certbot` (do not detach, to check that everything goes right)
- uncomment 443 config in `nginx.conf`
- reup `nginx`~~

Now to make all new certificates in bulk, stop any service running behind port:80i (this will already stop `traefik` container if running and start it again), and run `makecerts`, be sure to export the variables `$SERVER_DOMAIN` and `$SERVER_SUBDOMAINS`, to emit certificates for all subdomains
```sh
zsh ~/makecerts
```
To add new domains simply run the script again

> REMEMBER: you have to provide variables `SERVER_DOMAINS` and `CERTBOT_EMAIL` to the compose or manually set them (I use `~/.env`)

### File template

Nginx config is a template file from which the actual config is generated, make sure to set executable permission to `~/nginx/makeconf.sh`

### Automatic cetificate renew

I am using crontab to schedule this rather than `systemd.Tiemer`s because it's mch easier to handle

> Install a crontab manager if your distro doesn't have a default one (like `cronie`, plus do all the needed stuff like actually starting the cron daemon *wink wink*) and load the crontab file for your user

## Tmux prefix changed

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
- Autoredirection from `/` to `/admin` for pihole is set by default after settig `webserver.domain` in `pihole.toml` in the pihole config
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

# Config sync

Copy relevant files to a git repo to save confit (requires to define `GITREPO` in the env to locate the git root)

> Copy the current config from the server to the github repository

> ```sh
> sh gitdump.sh
> ```

## ADD:

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
