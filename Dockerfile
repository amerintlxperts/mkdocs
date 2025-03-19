FROM python:3.11 AS build

# Build-time flags
ARG WITH_PLUGINS=true
ARG DEBIAN_FRONTEND=noninteractive

# Environment variables
ENV PACKAGES="/usr/local/lib/python3.11/site-packages" \
    PYTHONDONTWRITEBYTECODE="1" \
    PYTHONUNBUFFERED="1" \
    PYTHONFAULTHANDLER="1" \
    PLAYWRIGHT_BROWSERS_PATH="/ms-playwright" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"

# Copy necessary files
COPY material material
COPY package.json package.json
COPY README.md README.md
COPY requirements.txt requirements.txt
COPY pyproject.toml pyproject.toml

# Install system dependencies and clean up in one step
RUN mkdir -p /etc/apt/keyrings && \
    curl -sL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >> /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y \
    build-essential \
    ca-certificates \
    chromium \
    curl \
    fonts-dejavu \
    fonts-droid-fallback \
    fonts-freefont-ttf \
    fonts-liberation \
    fonts-noto \
    fonts-noto-color-emoji \
    fonts-wqy-zenhei \
    git \
    gobject-introspection \
    libjpeg-dev \
    libcairo2 \
    libcairo2-dev \
    libfreetype6-dev \
    libffi-dev \
    libssl-dev \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    libpango1.0-dev \
    libharfbuzz-dev \
    libopenjp2-7-dev \
    openssh-client \
    tini \
    yarn \
    xvfb \
    weasyprint \
    zlib1g-dev && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install Python dependencies in one step
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir . && \
    pip install --no-cache-dir \
    mkdocs-material[recommended] \
    mkdocs-material[imaging]

# Link themes
RUN for theme in mkdocs readthedocs; do \
    rm -rf ${PACKAGES}/mkdocs/themes/$theme && \
    ln -s ${PACKAGES}/material/templates ${PACKAGES}/mkdocs/themes/$theme; \
  done

# Install Playwright and its dependencies in one step
RUN mkdir -p /ms-playwright && \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright npm install -g playwright && \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright playwright install --with-deps && \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright playwright install chromium && \
    chmod -R 777 /ms-playwright && \
    apt-get autoremove -y --purge build-essential libffi-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /root/.cache

# Set up fonts
RUN mkdir -p /var/cache/fontconfig && \
    chmod -R 777 /var/cache/fontconfig && \
    fc-cache -f

# Configure git
RUN mkdir -p /tmp/docs /tmp/site && \
    git config --system --add safe.directory /tmp/docs && \
    git config --system --add safe.directory /tmp/site && \
    echo "INHERIT: docs/theme/mkdocs.yml" > "/tmp/mkdocs.yml"

# From empty image
FROM scratch

# Copy all from build
COPY --from=build / /

# Set working directory
WORKDIR /tmp

# Expose MkDocs development server port
EXPOSE 8000

# Start development server by default
ENTRYPOINT ["/usr/bin/tini", "--", "mkdocs"]
CMD ["serve", "--dev-addr=0.0.0.0:8000"]
