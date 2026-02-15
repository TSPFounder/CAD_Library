#!/usr/bin/env python3
"""
Build SQLite Database from SQL Schema Files

This script creates a SQLite database file from all SQL schema files
located in the CAD_Library/SQL directory.

Usage:
    python3 build_database.py [output_file]
    
Arguments:
    output_file: Optional path to the output database file.
                 Default: CAD_Library.db
                 
Example:
    python3 build_database.py CAD_Library.sqlite
"""

import sqlite3
import sys
import os
from pathlib import Path


def build_database(output_file='CAD_Library.db'):
    """
    Build SQLite database from SQL schema files.
    
    Args:
        output_file: Path to the output database file
        
    Returns:
        True if successful, False otherwise
    """
    # Get the directory containing this script
    script_dir = Path(__file__).parent
    sql_dir = script_dir / 'CAD_Library' / 'SQL'
    
    # Check if SQL directory exists
    if not sql_dir.exists():
        print(f"Error: SQL directory not found at {sql_dir}")
        return False
    
    # Get all SQL files
    sql_files = sorted(sql_dir.glob('*.sql'))
    
    if not sql_files:
        print(f"Error: No SQL files found in {sql_dir}")
        return False
    
    print(f"Found {len(sql_files)} SQL schema files")
    
    # Remove existing database file if it exists
    output_path = script_dir / output_file
    if output_path.exists():
        print(f"Removing existing database file: {output_path}")
        output_path.unlink()
    
    # Create database and execute SQL files
    try:
        print(f"\nCreating database: {output_path}")
        conn = sqlite3.connect(str(output_path))
        cursor = conn.cursor()
        
        # Execute each SQL file
        for sql_file in sql_files:
            print(f"  Processing: {sql_file.name}")
            
            try:
                with open(sql_file, 'r', encoding='utf-8') as f:
                    sql_content = f.read()
                
                # Execute the SQL statements
                cursor.executescript(sql_content)
                
            except sqlite3.Error as e:
                print(f"    Warning: Error processing {sql_file.name}: {e}")
                # Continue with other files even if one fails
                continue
        
        # Commit all changes
        conn.commit()
        
        # Get database statistics
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
        tables = cursor.fetchall()
        
        cursor.execute("SELECT name FROM sqlite_master WHERE type='view' ORDER BY name")
        views = cursor.fetchall()
        
        cursor.execute("SELECT name FROM sqlite_master WHERE type='index' ORDER BY name")
        indexes = cursor.fetchall()
        
        print(f"\n✓ Database created successfully!")
        print(f"  Location: {output_path}")
        print(f"  Size: {output_path.stat().st_size:,} bytes")
        print(f"  Tables: {len(tables)}")
        print(f"  Views: {len(views)}")
        print(f"  Indexes: {len(indexes)}")
        
        # Close connection
        conn.close()
        
        return True
        
    except sqlite3.Error as e:
        print(f"\nError: Failed to create database: {e}")
        return False
    except Exception as e:
        print(f"\nError: Unexpected error: {e}")
        return False


def main():
    """Main entry point for the script."""
    # Check if output file is provided
    output_file = sys.argv[1] if len(sys.argv) > 1 else 'CAD_Library.db'
    
    print("=" * 60)
    print("SQLite Database Builder for CAD Library")
    print("=" * 60)
    
    # Build the database
    success = build_database(output_file)
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
