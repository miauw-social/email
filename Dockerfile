FROM python:alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache -r requirements.txt
COPY src/ .
CMD ["python", "main.py"]