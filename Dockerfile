# Keep ARG outside of build images so can access globally
# This is not ideal. The tarballs are not named nicely and EnergyPlus versioning is strange
ARG ENERGYPLUS_VERSION
ARG ENERGYPLUS_SHA
ARG ENERGYPLUS_INSTALL_VERSION
ARG ENERGYPLUS_TAG
ARG UBUNTU_BASE=22.04

FROM ubuntu:$UBUNTU_BASE AS base

ARG ENERGYPLUS_VERSION
ARG ENERGYPLUS_SHA
ARG ENERGYPLUS_INSTALL_VERSION
ARG ENERGYPLUS_TAG
ARG UBUNTU_BASE

ENV ENERGYPLUS_VERSION=$ENERGYPLUS_VERSION
ENV ENERGYPLUS_TAG=$ENERGYPLUS_TAG
ENV ENERGYPLUS_SHA=$ENERGYPLUS_SHA
ENV UBUNTU_BASE=$UBUNTU_BASE

# This should be x.y.z, but EnergyPlus convention is x-y-z
ENV ENERGYPLUS_INSTALL_VERSION=$ENERGYPLUS_INSTALL_VERSION

ENV ENERGYPLUS_DOWNLOAD_BASE_URL=https://github.com/NatLabRockies/EnergyPlus/releases/download/$ENERGYPLUS_TAG
ENV SIMDATA_DIR=/var/simdata

# Download and install - determine architecture at runtime
# Map aarch64 to arm64 for EnergyPlus package naming
RUN apt-get update \
    && apt-get install -y ca-certificates curl libx11-6 libexpat1 python3 python3-pip $(["$UBUNTU_BASE" = "22.04"] && echo -n "libmd0") \
    && rm -rf /var/lib/apt/lists/* \
    && ARCH=$(uname -m) \
    && if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi \
    && ENERGYPLUS_DOWNLOAD_BASENAME="EnergyPlus-${ENERGYPLUS_VERSION}-${ENERGYPLUS_SHA}-Linux-Ubuntu${UBUNTU_BASE}-${ARCH}" \
    && ENERGYPLUS_DOWNLOAD_FILENAME="${ENERGYPLUS_DOWNLOAD_BASENAME}.tar.gz" \
    && ENERGYPLUS_DOWNLOAD_URL="${ENERGYPLUS_DOWNLOAD_BASE_URL}/${ENERGYPLUS_DOWNLOAD_FILENAME}" \
    && echo "Downloading: ${ENERGYPLUS_DOWNLOAD_URL}" \
    && curl -SLO ${ENERGYPLUS_DOWNLOAD_URL} \
    && tar -zxvf ${ENERGYPLUS_DOWNLOAD_FILENAME} \
    && cd ${ENERGYPLUS_DOWNLOAD_BASENAME} \
    && chmod +x energyplus \
    && ln -s energyplus EnergyPlus \
    && mkdir -p $SIMDATA_DIR/energyplus \
    && cp ExampleFiles/1ZoneUncontrolled.idf $SIMDATA_DIR \
    && cp ExampleFiles/PythonPluginCustomOutputVariable.idf $SIMDATA_DIR \
    && cp ExampleFiles/PythonPluginCustomOutputVariable.py $SIMDATA_DIR \
    && rm ../${ENERGYPLUS_DOWNLOAD_FILENAME} \
    && rm -rf DataSets Documentation ExampleFiles WeatherData MacroDataSets PostProcess/convertESOMTRpgm \
    PostProcess/EP-Compare PreProcess/FMUParser PreProcess/ParametricPreProcessor PreProcess/IDFVersionUpdater \
    && mv ../${ENERGYPLUS_DOWNLOAD_BASENAME} /energyplus

# Use Multi-stage build to produce a smaller final image
FROM ubuntu:${UBUNTU_BASE} AS runtime

ARG ENERGYPLUS_VERSION
ARG ENERGYPLUS_SHA
ARG UBUNTU_BASE

ENV ENERGYPLUS_VERSION=$ENERGYPLUS_VERSION
ENV ENERGYPLUS_SHA=$ENERGYPLUS_SHA
ENV UBUNTU_BASE=$UBUNTU_BASE
ENV SIMDATA_DIR=/var/simdata

# Copy EnergyPlus installation
COPY --from=base /energyplus /energyplus
COPY --from=base $SIMDATA_DIR $SIMDATA_DIR

# Install runtime dependencies
RUN apt-get update \
    && apt-get install -y libx11-6 libexpat1 libgomp1 $(["$UBUNTU_BASE" = "22.04"] && echo -n "libmd0") \
    && rm -rf /var/lib/apt/lists/*

# Add energyplus to PATH so can run "energyplus" in any directory
ENV PATH="/energyplus:${PATH}"
CMD [ "/bin/bash" ]
