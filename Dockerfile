FROM squidfunk/mkdocs-material:latest
COPY requirements.txt ./
RUN apk add --no-cache \
  cairo-dev \
  font-noto \
  g++ \
  gcc \
  gobject-introspection \
  harfbuzz-subset \
  jpeg-dev \
  libffi-dev \
  musl-dev \
  openjpeg-dev \
  pango \
  pango-dev \
  py3-cffi \
  py3-pip \
  python3-dev \
  ttf-dejavu \
  ttf-freefont \
  weasyprint \
  zlib-dev
RUN apk --no-cache add msttcorefonts-installer fontconfig && \
    update-ms-fonts && \
    fc-cache -f
RUN pip install -U -r requirements.txt
RUN echo "[safe] \n        directory = /docs/docs" > /.gitconfig
