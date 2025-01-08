FROM squidfunk/mkdocs-material:latest
COPY requirements.txt ./
RUN apk add --no-cache \
  cairo-dev \
  chromium \
  curl \
  freetype \
  fontconfig \
  font-noto \
  font-noto-emoji \
  gobject-introspection \
  harfbuzz \
  harfbuzz-subset \
  libstdc++ \
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
  weasyprint \
  wqy-zenhei

ENV CHROME_BIN=/usr/bin/chromium-browser \
    CHROME_PATH=/usr/lib/chromium/ \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

RUN npm install -g playwright && \
    npx playwright install --with-deps

RUN update-ms-fonts && \
    fc-cache -f

RUN pip install -U -r requirements.txt
RUN echo "[safe]" > /.gitconfig
RUN echo "        directory = /docs/docs" >> /.gitconfig
