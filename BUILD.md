# Building and Publishing EnergyPlus Docker Images

## Prerequisites
Docker desktop should be installed and running.

Setup multi-platform builder (one-time):
```bash
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap
```
## Build Examples
### Build for x86_64 (AMD64)
To be used for example for a HPC build.
```bash
docker buildx build \
  --platform linux/amd64 \
  --target runtime \
  -t energyplus:26.1.0-x86_64 \
  -t docker.artifactory.pnnl.gov/energyplus/energyplus:26.1.0-x86_64 \
  --build-arg ENERGYPLUS_VERSION=26.1.0 \
  --build-arg ENERGYPLUS_SHA=6f2e40d102 \
  --build-arg ENERGYPLUS_INSTALL_VERSION=26-1-0 \
  --build-arg ENERGYPLUS_TAG=v26.1.0 \
  --build-arg UBUNTU_BASE=24.04 \
  --load \
  .
```

### Build for ARM64
To be used for example for a computer using an Apple M-series chip.

```bash
docker buildx build \
  --platform linux/arm64 \
  --target runtime \
  -t energyplus:26.1.0-arm64 \
  -t docker.artifactory.pnnl.gov/energyplus/energyplus:26.1.0-arm64 \
  --build-arg ENERGYPLUS_VERSION=26.1.0 \
  --build-arg ENERGYPLUS_SHA=6f2e40d102 \
  --build-arg ENERGYPLUS_INSTALL_VERSION=26-1-0 \
  --build-arg ENERGYPLUS_TAG=v26.1.0 \
  --build-arg UBUNTU_BASE=24.04 \
  --load \
  .
```

## Push to Artifactory

```bash
docker push docker.artifactory.pnnl.gov/energyplus/energyplus:26.1.0-x86_64
docker push docker.artifactory.pnnl.gov/energyplus/energyplus:26.1.0-arm64
```

## Build Arguments Reference

- `ENERGYPLUS_VERSION`: Version number (e.g., 26.1.0)
- `ENERGYPLUS_SHA`: Git commit SHA from release tag
- `ENERGYPLUS_INSTALL_VERSION`: Version with dashes (e.g., 26-1-0)
- `ENERGYPLUS_TAG`: Git tag (e.g., v26.1.0)
- `UBUNTU_BASE`: Ubuntu base image version (22.04 or 24.04)
