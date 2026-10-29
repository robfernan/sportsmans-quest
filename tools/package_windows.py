#!/usr/bin/env python3
"""Zip a Windows export that is already in dist/. See tools/export_release.py."""

import os
import runpy
import sys

sys.argv = [sys.argv[0], "zip-windows"]
os.chdir(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
runpy.run_path(os.path.join(os.path.dirname(__file__), "export_release.py"), run_name="__main__")
