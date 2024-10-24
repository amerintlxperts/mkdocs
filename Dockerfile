FROM squidfunk/mkdocs-material:latest
COPY requirements.txt ./
RUN apk add --no-cache g++
RUN pip install -U -r requirements.txt
RUN addgroup -g 114 docker && adduser -h /docs -D -u 1001 runner -G docker
USER runner
