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
