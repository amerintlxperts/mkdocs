FROM squidfunk/mkdocs-material:latest
COPY requirements.txt ./
RUN apk add --no-cache g++
RUN pip install -U -r requirements.txt
