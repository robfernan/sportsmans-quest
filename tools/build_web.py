#!/usr/bin/env python3
"""Build the nothreads web export. See tools/export_release.py."""

import os
import runpy
import sys

sys.argv = [sys.argv[0], "web"]
os.chdir(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
runpy.run_path(os.path.join(os.path.dirname(__file__), "export_release.py"), run_name="__main__")
