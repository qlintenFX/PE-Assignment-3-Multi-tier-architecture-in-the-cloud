#!/bin/bash
set -e

# Print environment variables (except secrets)
echo "========== Environment Debug =========="
env | grep -v SECRET | grep -v PASSWORD
echo "======================================="

# Initialize the database
echo "Initializing database..."
python3 -c "
from app import db
from app.models import Entry
import time
import os
import traceback
import pymysql

# Display database connection string (without password)
db_url = os.environ.get('DATABASE_URL', 'None')
if db_url and 'mysql' in db_url:
    print(f'Using database: {db_url.split('@')[1].split('/')[0]}')

# Try multiple times to initialize the database
max_tries = 10
tries = 0
while tries < max_tries:
    try:
        # Try connecting to the database directly first to check connectivity
        if 'mysql' in db_url:
            connection_parts = db_url.replace('mysql+pymysql://', '').split('@')[0].split(':')
            user = connection_parts[0]
            # Don't print the password
            host_parts = db_url.split('@')[1].split('/')
            host = host_parts[0]
            db_name = host_parts[1].split('?')[0]
            
            print(f'Testing direct database connection to {host} as {user}...')
            conn = pymysql.connect(
                host=host.split(':')[0],
                user=user,
                password=os.environ.get('DATABASE_PASSWORD') or connection_parts[1],
                database=db_name
            )
            print('Direct database connection successful!')
            
            # Test if we can create tables
            cursor = conn.cursor()
            try:
                print('Checking if entry table exists...')
                cursor.execute('SHOW TABLES LIKE \"entry\"')
                result = cursor.fetchone()
                if result:
                    print('Table entry already exists')
                else:
                    print('Table entry does not exist, will create it')
            except Exception as e:
                print(f'Error checking tables: {e}')
            finally:
                cursor.close()
                conn.close()
        
        # Create tables
        print('Creating all database tables via SQLAlchemy...')
        db.create_all()
        print('Tables created successfully!')
        
        # Verify tables were created
        from sqlalchemy import inspect
        inspector = inspect(db.engine)
        tables = inspector.get_table_names()
        print(f'Tables in database: {tables}')
        if 'entry' in tables:
            print('Entry table was created successfully!')
        else:
            print('WARNING: Entry table was not created!')
            
        break
    except Exception as e:
        tries += 1
        print(f'Error initializing database (attempt {tries}/{max_tries}): {e}')
        traceback.print_exc()
        if tries >= max_tries:
            print('Failed to initialize database after multiple attempts')
            print('Continuing anyway - maybe the app will work if tables already exist')
        # Wait before retrying
        time.sleep(5)
"

# Start the gunicorn server
echo "Starting Gunicorn WSGI server..."
exec gunicorn --bind 0.0.0.0:8000 wsgi:app 