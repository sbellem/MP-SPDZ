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
docker build --target base --tag mpspdz:base .
```

To push to DockerHub, tag the image accordingly, e.g.:

```shell
docker tag mpspdz:base intic3/mpspdz:$(git log -n 1 --format:%h)
```

and push it:

```shell
docker push intic3/mpspdz:$(git log -n 1 --format:%h)
```

## Building a program (e.g.: `malicious-shamir-offline.x`)
A specific program can be built by passing the `--build-arg` option to docker.

For example, to build `mal-shamir-offline.x`:

```shell
docker build --tag mal-shamir-offline.x --build-arg program=mal-shamir-offline.x .
```

The default `program` is `malicious-shamir-party.x`. So you don't need to
pass it when when building the image.

### Publishing the image to DockerHub
Tag it and push, e.g.:

```shell
docker tag mal-shamir-offline.x:latest \
    intic3/mal-shamir-offline.x:$(git log -n 1 --pretty=format:%h)
```

and publish it:

```shell
docker push intic3/mal-shamir-offline.x:$(git log -n 1 --pretty=format:%h)
```

### Additional build arguments
Other build arguments, and their default are:

`n=4`: number of players
`mod="-DGFP_MOD_SZ=4": for primes > 256 bits, number of limbs (prime length
    divided by 64 rounded up)
prep_dir="/opt/preprocessing-data": directory where to store preprocessing data

See the `ARG` instructions in the [`Dockerfile`](./Dockerfile).

### Building `malicious-shamir-party.x`

```shell
docker build --tag malicious-shamir-party.x .
```

#### Tag and publish
```shell
docker tag malicious-shamir-party.x:latest \
    initc3/malicious-shamir-party.x:$(git log -n 1 --pretty=format:%h)
```
```shell
docker push intic3/malicious-shamir-party.x:$(git log -n 1 --pretty=format:%h)
```
