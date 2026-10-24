#!/usr/bin/env python3
import os, sys
os.environ.pop('DATABASE_URL', None)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app import app
app.run(host='0.0.0.0', port=9999, debug=False, threaded=True)
