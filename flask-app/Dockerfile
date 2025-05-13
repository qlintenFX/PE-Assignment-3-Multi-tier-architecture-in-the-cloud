FROM python:3.9-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Gunicorn
RUN pip install --no-cache-dir gunicorn

# Copy the application
COPY . .

# Make the entrypoint script executable
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set environment variables
ENV PYTHONUNBUFFERED 1
ENV FLASK_APP crudapp.py

# Expose port 8000
EXPOSE 8000

# Run the entrypoint script
ENTRYPOINT ["/entrypoint.sh"] 