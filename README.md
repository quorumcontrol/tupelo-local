# tupelo-local
A convience docker image that launches a fully local tupelo. All it requires is a conventionally configured `docker-compose.yml`

``` yaml
version: "3"

services:
  tupelo:
    image: quorumcontrol/tupelo-local:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - tupelo-local:/tupelo-local
    environment:
      TUPELO_VERSION: latest
      COMMUNITY_VERSION: latest

# Customize below this line
  tester:
    build: .
    entrypoint: ["/tupelo-local/wait-for-tupelo.sh"]
    command: ["npm", "run", "test"]
    volumes:
      - tupelo-local:/tupelo-local
# Customize above this line

networks:
  default:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.16.247.0/24

volumes:
  tupelo-local:
```

3 important pieces to point out:
- tupelo container that mounts `docker.sock` and `/tupelo-local` volume
- a default network with `172.16.247.0/24` subnet
- a defined `tupelo-local` volume

Then simply use docker for tests / app in a container as normal. Mounting `tupelo-local:/tupelo-local` will provide assitance in running against this localnet:
- notary group config at `/tupelo-local/config/notarygroup.toml`
- `/tupelo-local/wait-for-tupelo.sh` which will sleep until tupelo is running, then exec the provided command