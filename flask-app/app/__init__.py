from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from dotenv import load_dotenv
import os

# Load environment variables from .env file if present
load_dotenv()

app = Flask(__name__)
app.config.from_object('app.config.Config')
db = SQLAlchemy(app)
migrate = Migrate(app, db)

from app import routes, models
