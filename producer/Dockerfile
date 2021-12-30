FROM python:2.7-onbuild
ENV PYTHONPATH /usr/src/app
WORKDIR /app
COPY producer.py /app
COPY requirements.txt /app
RUN pip install --requirement /app/requirements.txt
