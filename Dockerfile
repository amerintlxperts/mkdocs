FROM python:3.11 AS build

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
RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y --no-install-recommends \
    libcairo2 \
    libcairo2-dev \
    libfreetype6-dev \
    git \
    libjpeg-dev \
    openssh-client \
    tini \
    zlib1g-dev \
    build-essential \
    libffi-dev 

RUN pip install --no-cache-dir --upgrade pip

RUN pip install --no-cache-dir .

RUN pip install --no-cache-dir \
      mkdocs-material[recommended] \
      mkdocs-material[imaging];

RUN for theme in mkdocs readthedocs; do \
    rm -rf ${PACKAGES}/mkdocs/themes/$theme; \
    ln -s \
      ${PACKAGES}/material/templates \
      ${PACKAGES}/mkdocs/themes/$theme; \
  done

RUN apt-get autoremove -y --purge build-essential libffi-dev
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /root/.cache

RUN find ${PACKAGES} \
    -type f \
    -path "*/__pycache__/*" \
    -exec rm -f {} \;

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

