#!/usr/bin/env python3
"""
Python Launcher - Direct launcher for running Python scripts
"""

import subprocess
import sys
import os


def find_python_executable():
    """Find available Python executable"""
    python_commands = ['python3', 'python']
    
    for cmd in python_commands:
        try:
            result = subprocess.run(
                ['which', cmd],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                return cmd.strip()
        except Exception:
            continue
    
    return None


def run_script(script_path, args=None, python_cmd='python3'):
    """Run a Python script"""
    if not os.path.exists(script_path):
        print(f"Error: Script '{script_path}' not found")
        sys.exit(1)
    
    cmd = [python_cmd, script_path]
    if args:
        cmd.extend(args)
    
    # 获取脚本所在目录作为工作目录
    script_dir = os.path.dirname(os.path.abspath(script_path))
    
    try:
        result = subprocess.run(cmd, cwd=script_dir)
        sys.exit(result.returncode)
    except Exception as e:
        print(f"Error running script: {e}")
        sys.exit(1)


def main():
    """Main launcher function - directly run the script"""
    python_cmd = find_python_executable()
    
    if not python_cmd:
        print("Error: Python not found. Please install Python.")
        sys.exit(1)
    
    if len(sys.argv) < 2:
        print("Usage: python_launcher.py <script.py> [args...]")
        print("Error: No script specified")
        sys.exit(1)
    
    script_path = sys.argv[1]
    args = sys.argv[2:] if len(sys.argv) > 2 else None
    
    run_script(script_path, args=args, python_cmd=python_cmd)


if __name__ == '__main__':
    main()
