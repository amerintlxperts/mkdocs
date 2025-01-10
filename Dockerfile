FROM python:3 AS build

# Build-time flags
ARG WITH_PLUGINS=true

# Environment variables
ENV PACKAGES=/usr/local/lib/python3.11/site-packages
ENV PYTHONDONTWRITEBYTECODE=1

# Set build directory
WORKDIR /tmp

# Copy files necessary for build
COPY material material
COPY package.json package.json
COPY README.md README.md
COPY *requirements.txt ./
COPY pyproject.toml pyproject.toml

# Perform build and cleanup artifacts and caches
RUN \
  apt-get update \
&& \
  apt-get upgrade -y \
&& \
  apt-get install -y --no-install-recommends \
    libcairo2 \
    libcairo2-dev \
    libfreetype6-dev \
    git \
    git-fast-import \
    libjpeg-dev \
    openssh-client \
    tini \
    zlib1g-dev \
    build-essential \
    libffi-dev \
&& \
  pip install --no-cache-dir --upgrade pip \
&& \
  pip install --no-cache-dir . \
&& \
  if [ "${WITH_PLUGINS}" = "true" ]; then \
    pip install --no-cache-dir \
      mkdocs-material[recommended] \
      mkdocs-material[imaging]; \
  fi \
&& \
  if [ -e user-requirements.txt ]; then \
    pip install -U -r user-requirements.txt; \
  fi \
&& \
  for theme in mkdocs readthedocs; do \
    rm -rf ${PACKAGES}/mkdocs/themes/$theme; \
    ln -s \
      ${PACKAGES}/material/templates \
      ${PACKAGES}/mkdocs/themes/$theme; \
  done \
&& \
  apt-get autoremove -y --purge build-essential libffi-dev \
&& \
  apt-get clean \
&& \
  rm -rf /var/lib/apt/lists/* /tmp/* /root/.cache \
&& \
  find ${PACKAGES} \
    -type f \
    -path "*/__pycache__/*" \
    -exec rm -f {} \; \
&& \
  git config --system --add safe.directory /docs \
&& \
  git config --system --add safe.directory /site

# From empty image
FROM scratch

# Copy all from build
COPY --from=build / /

# Set working directory
WORKDIR /docs

# Expose MkDocs development server port
EXPOSE 8000

# Start development server by default
ENTRYPOINT ["/usr/bin/tini", "--", "mkdocs"]
CMD ["serve", "--dev-addr=0.0.0.0:8000"]

