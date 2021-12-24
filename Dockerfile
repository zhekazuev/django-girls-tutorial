# Flask uses gunicorn like a wsgi
# Python base
FROM python:3.8-alpine AS base

# Stage 1 - Compile scss and minimize html/css
# FROM node:alpine AS front-compiler
# WORKDIR /django
# COPY tailwind.config.js ./
# COPY package*.json ./
# RUN npm ci
# COPY src/ ./src/
# # COPY src/templates/ ./src/templates/
# RUN npm run build

# Stage 2 - Delete python trash and build
FROM base as builder
RUN mkdir /install
WORKDIR /install
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir --prefix=/install -r /requirements.txt
RUN find /install -name '*.c' -delete
RUN find /install -name '*.pxd' -delete
RUN find /install -name '*.pyd' -delete
RUN find /install -name '*.pyo' -delete
RUN find /install -name '*.pyc' -delete
RUN find /install -name '__pycache__' | xargs rm -r

# Stage 3 - Copy files and run
FROM base
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PORT 8000
EXPOSE $PORT
COPY --from=builder /install /usr/local/
# COPY requirements.txt requirements.txt
# RUN pip install --no-cache-dir -r requirements.txt
COPY src/ ./
# COPY --from=front-compiler /django/src/static/ ./static/
# COPY --from=front-compiler /django/src/ ./
# CMD python manage.py collectstatic --noinput && \
CMD python manage.py makemigrations && \
    python manage.py migrate && \
    gunicorn --workers 1 --bind :$PORT core.wsgi
