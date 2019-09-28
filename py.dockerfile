FROM python:3.7-alpine
WORKDIR /app
COPY ./python/requirements.txt /app
RUN pip install -r requirements.txt
