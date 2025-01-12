FROM python:3.11 AS build

# Build-time flags
ARG WITH_PLUGINS=true

# Environment variables
ENV PACKAGES=/usr/local/lib/python3.11/site-packages
ENV PYTHONDONTWRITEBYTECODE=1
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# Set build directory
WORKDIR /tmp

# Copy files necessary for build
COPY material material
COPY package.json package.json
COPY README.md README.md
COPY requirements.txt requirements.txt
COPY pyproject.toml pyproject.toml

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcairo2 libcairo2-dev libfreetype6-dev git libjpeg-dev openssh-client \
    tini zlib1g-dev build-essential libffi-dev ca-certificates chromium curl \
    fonts-dejavu fonts-droid-fallback fonts-freefont-ttf fonts-liberation \
    fonts-noto fonts-noto-color-emoji fonts-wqy-zenhei gobject-introspection \
    libssl-dev libx11-dev libxext-dev libxrender-dev libpango1.0-dev \
    libharfbuzz-dev libopenjp2-7-dev nodejs npm xvfb weasyprint && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install Python dependencies
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir .
RUN pip install --no-cache-dir \
    mkdocs-material[recommended] \
    mkdocs-material[imaging]

# Link themes
RUN for theme in mkdocs readthedocs; do \
    rm -rf ${PACKAGES}/mkdocs/themes/$theme; \
    ln -s \
      ${PACKAGES}/material/templates \
      ${PACKAGES}/mkdocs/themes/$theme; \
  done

# Install Playwright and its dependencies
RUN pip install playwright
RUN mkdir -p /ms-playwright && \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright playwright install --with-deps

# Keep Playwright browsers available in the final image
RUN chmod -R 777 /ms-playwright

# Clean up unnecessary files
RUN apt-get autoremove -y --purge build-essential libffi-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /root/.cache

# Set up fonts
RUN mkdir -p /var/cache/fontconfig && \
    chmod -R 777 /var/cache/fontconfig && \
    fc-cache -f

# Configure git
RUN git config --system --add safe.directory /docs 
RUN git config --system --add safe.directory /site

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
