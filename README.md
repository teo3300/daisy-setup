# daisy-setup

Simple repository to keep all my server config and mini scripts, because I know myself and am sure I'll break everything someday

# What this provides

## DNS records update
`dnsupdate.service` and `dnupdate.timer` provide a timer to update dns records according to the script inside the `dns` folder using [dynamicdns.park-your-domain.com](https://dynamicdns.park-your-domain.com)
- create a file ```"~/dns/secrets_domain"``` containing the domais to update
- create a file ```"~/dns/secrets_password"```containing your dns pasword for authentication

## Wireguard interface creation
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

## Services setup
`docker-compose.yml` sets up
- `nginx` reverse proxy to manage certificates
- `bitwarden` password manager
- `pi-hole` local DNS for ad blocking
