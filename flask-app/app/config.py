import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class Config(object):
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-key-for-development-only'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///' + os.path.join(os.path.abspath(os.path.dirname(__file__)), '..', 'app.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False