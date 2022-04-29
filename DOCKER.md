# Building Docker Images
Please note, that this document is geared towards building docker images for
the HoneyBadgerSwap research project. That being said, it may be quite simple
to adapt it to your own research and development needs. **This is by no means
meant for production use.**

## Building the MP-SPDZ Base Image
Clone the MP-SPDZ repository fork, e.g.

```shell
git clone --branch dev https://github.com/initc3/MP-SPDZ.git /tmp/MP-SPDZ
```

If you need a specific commit or branch, check it out, e.g.:

```shell
git checkout d686efcada9efef08cd0573e1aafc478f02d5fcf
```

```shell
docker build --target bulidenv --tag mpspdz:bulidenv .
```

To push to DockerHub, tag the image accordingly, e.g.:

```shell
docker tag mpspdz:base initc3/mpspdz:$(git log -n 1 --pretty=format:%h)
```

and push it:

```shell
docker push initc3/mpspdz:$(git log -n 1 --pretty=format:%h)
```

## Building a program: `mal-shamir-offline.x`
A specific program can be built by passing the `--build-arg` option to docker.

For example, to build `mal-shamir-offline.x`:

```shell
docker build \
        --tag mpspdz:mal-shamir-offline.x \
        --target machine \
        --build-arg machine=mal-shamir-offline.x \
        --build-arg gfp_mod_sz=4 \
        --build-arg prep_dir=/opt/preprocessing-data \
        --build-arg ssl_dir=/opt/ssl \
        --build-arg cryptoplayers=4 .
```

### Publishing the image to DockerHub
Tag it and push, e.g.:

```shell
docker tag mal-shamir-offline.x:latest \
    initc3/mal-shamir-offline.x:$(git log -n 1 --pretty=format:%h)
```

and publish it:

```shell
docker push initc3/mal-shamir-offline.x:$(git log -n 1 --pretty=format:%h)
```

### Additional build arguments
`cryptoplayers=4`: number of players
`gfp_mod_sz=4`: for primes > 256 bits, number of limbs (prime length
    divided by 64 rounded up)
`prep_dir="/opt/preprocessing-data"`: directory where to store preprocessing data

For other build arguments, see the `ARG` instructions in the
[`Dockerfile`](./Dockerfile).

## Building `malicious-shamir-party.x`

```shell
docker build \
        --tag mpspdz:malicious-shamir-party.x \
        --target machine \
        --build-arg machine=malicious-shamir-party.x \
        --build-arg gfp_mod_sz=4 \
        --build-arg prep_dir=/opt/preprocessing-data \
        --build-arg ssl_dir=/opt/ssl \
        --build-arg cryptoplayers=4 .
```

### Tag and publish
```shell
docker tag malicious-shamir-party.x:latest \
    initc3/malicious-shamir-party.x:$(git log -n 1 --pretty=format:%h)
```
```shell
docker push initc3/malicious-shamir-party.x:$(git log -n 1 --pretty=format:%h)
```

## Building `random-shamir.x`

```shell
docker build \
    --tag mpspdz:random-shamir.x \
    --target machine \
    --build-arg machine=random-shamir.x \
    --build-arg gfp_mod_sz=4 \
    --build-arg prep_dir=/opt/inputmask-shares \
    --build-arg ssl_dir=/opt/ssl \
    --build-arg cryptoplayers=4 .
```

### Tag and publish
```shell
docker tag random-shamir.x:latest \
    initc3/random-shamir.x:$(git log -n 1 --pretty=format:%h)
```
```shell
docker push initc3/random-shamir.x:$(git log -n 1 --pretty=format:%h)
```
