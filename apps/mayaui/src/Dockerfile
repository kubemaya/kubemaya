
FROM python:3-alpine
WORKDIR /app
COPY requirements.txt .
RUN apk update
RUN apk add build-base gcc python3-dev musl-dev linux-headers
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8080
CMD ["ash", "-c", "python index.py"]
