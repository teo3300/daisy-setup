# === FROM OLD DAISY ===

# Daisy

I know myself and am sure I'll break everything someday

# What this provides

# Static IP
I'm using networkmanager because I am lazy.
According to [this blog](https://michlstechblog.info/blog/linux-set-a-static-fixed-ip-with-network-manager-cli/) static IP address can be requested via NetworkManager via

```sh
nmcli con mod "Wired connection 1"        \
  ipv4.addresses  "10.200.2.200/24"       \
  ipv4.gateway    "10.200.2.1"            \
  ipv4.dns        "10.200.2.2,10.200.2.3" \
  ipv4.dns-search "myDomain.org"          \
  ipv4.method     "manual"
```

## DNS records update
`dnsupdate.service` and `dnupdate.timer` provide a timer to update dns records according to the script inside the `dns` folder using [dynamicdns.park-your-domain.com](https://dynamicdns.park-your-domain.com)
- copy both the `.service` and `.timer` file in `/et/systemd/system`
- create a file ```"~/dns/secrets_domain"``` containing the domais to update
- create a file ```"~/dns/secrets_password"```containing your dns pasword for authentication
- *Remember to make these file not readable from other users* (`600` permissions)

## Wireguard interface creation

Create a file in the local wireguard directory, setting the variables
- `$SERVER_DOMAIN`
- `$SERVER_PORT`
And add executable privileges to the owner (better if setting `700` permissions)

Generate wireguard interface configurations using

```sh
# ./setup_server
```
to create the server config interface
```sh
# ./setup_client <hostname> <index_in_the_subnet>
```
to create the client config

To share config use something like qrencode, don't send your keys around the internet

# Docker keys generation
To generate keys move to the `~/docker` folder and create a `keys` file with permissions `700`
to add a new key as environment variable use the comand
```sh
./addkey <VARIABLE_NAME>
```
Remember to `source ~/docker/keys` before starting the docker compose

## Services setup
`docker-compose.yml` sets up
- `nginx` reverse proxy to manage certificates
- `bitwarden` password manager
- `pi-hole` local DNS for ad blocking

# === FROM OLD HABENARIA ===

# Habenaria

## Generate DB keys

1. If the system does not use any other disk encryption, encrypt the folder containing the key

    ```sh
    # fscrypt setup
    # fscrypt encrypt nextcloud/keys
    ```
    To unlock this folder use
    ```sh
    # fscrypt unlock nextcloud/keys
    ```

2. Generate keys to use for for MariaDB

    ```sh
    # openssl rand -base64 32 > nextcloud/keys/MYSQL_KEY
    # openssl rand -base64 32 > nextcloud/keys/MYSQL_ROOT_KEY
    ```

## Source DB keys

Source generated keys with

```sh
# source nextcloud/setkeys
```

## Services setup
Docker compose will set up
- `nginx-proxy-manager` to manage certificates
- `nextcloud`
- `mariadb`

Be sure **keys are sourced** and unlocked before starting the container,
otherwise it will have no access to the DB

## Proxy setup for nextcloud

Nextcloud notices being behind a reverse proxy, to prevent annoying warnings
configure nextcloud to recognise this proxy as trusted

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
