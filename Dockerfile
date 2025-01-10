FROM squidfunk/mkdocs-material:latest

COPY requirements.txt ./

RUN apk add --no-cache \
  cairo-dev \
  ca-certificates \
  chromium \
  curl \
  freetype \
  fontconfig \
  font-noto \
  g++ \
  gcc \
  font-noto-emoji \
  gobject-introspection \
  harfbuzz \
  harfbuzz-subset \
  jpeg-dev \
  libstdc++ \
  libffi-dev \
  libx11 \
  libxrender \
  libxext \
  libssl3 \
  musl-dev \
  msttcorefonts-installer \
  nodejs \
  npm \
  nss \
  openjpeg-dev \
  pango \
  pango-dev \
  py3-cffi \
  py3-pip \
  python3-dev \
  ttf-dejavu \
  ttf-freefont \
  ttf-droid \
  ttf-freefont \
  ttf-liberation \
  weasyprint \
  wqy-zenhei \
  xvfb

# Create and set writable permissions for fontconfig cache directory
RUN mkdir -p /var/cache/fontconfig && \
    chmod -R 777 /var/cache/fontconfig

RUN update-ms-fonts && \
    fc-cache -f

RUN pip install -U -r requirements.txt
RUN git config --global --add safe.directory '*'
