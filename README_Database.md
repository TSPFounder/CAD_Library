# CAD Library SQLite Database

This document describes how to generate a SQLite database from the SQL schema files in this repository.

## Overview

The CAD Library includes 31 SQL schema files in the `CAD_Library/SQL/` directory. These files define the complete database schema for storing CAD models, parts, assemblies, drawings, and related metadata.

## Generating the Database

### Prerequisites

- Python 3.6 or higher
- SQLite 3 (usually pre-installed on most systems)

### Quick Start

To create a SQLite database with the default name (`CAD_Library.db`):

```bash
python3 build_database.py
```

To create a database with a custom name:

```bash
python3 build_database.py my_database.sqlite
```

### Script Details

The `build_database.py` script:

1. Reads all SQL schema files from `CAD_Library/SQL/` directory
2. Creates a new SQLite database file
3. Executes each SQL schema file in alphabetical order
4. Reports statistics about the created database

### Database Contents

The generated database includes:

- **178 Tables**: Core data structures for CAD entities
- **42 Views**: Convenient queries for common data access patterns
- **337 Indexes**: Optimized for query performance

### Key Database Features

#### Main Tables

- **CAD_Model**: CAD models and their properties
- **CAD_Part**: Individual parts with metadata
- **CAD_Assembly**: Assembly structures and hierarchies
- **CAD_Drawing**: Technical drawings
- **CAD_File**: File management and versioning
- **CAD_Feature**: Design features
- **CAD_Sketch**: 2D sketches
- **CAD_Body**: 3D solid bodies
- **CAD_Surface**: Surface geometry
- **CAD_Dimension**: Engineering dimensions
- **CAD_Constraint**: Geometric constraints
- **CAD_Joint**: Assembly joints and connections
- **CAD_Configuration**: Design configurations
- **Point, Vector, CoordinateSystem**: Geometric primitives
- **MassProperties**: Physical properties (mass, inertia, etc.)

#### Junction Tables

Many junction tables support many-to-many relationships between entities (e.g., `CAD_Assembly_Component`, `CAD_Part_Body`, etc.)

#### Views

Pre-defined views provide convenient access to commonly needed data combinations (e.g., `v_CAD_Assembly_Detail`, `v_CAD_Part_Full`, etc.)

### Foreign Key Support

The database schema uses foreign keys to maintain referential integrity. Foreign keys are enabled by default in the schema files with:

```sql
PRAGMA foreign_keys = ON;
```

### Known Warnings

During database creation, you may see warnings about missing columns. These are expected and occur when views or indexes reference columns from tables defined in other schema files. The database creation continues and completes successfully despite these warnings.

## Schema Files

The following SQL schema files are included:

1. CAD_Assembly_Schema.sql
2. CAD_BoM_Schema.sql
3. CAD_Body_Schema.sql
4. CAD_Component_Schema.sql
5. CAD_Configuration_Schema.sql
6. CAD_Constraint_Schema.sql
7. CAD_ConstructionGeometry_Schema.sql
8. CAD_Dimension_Schema.sql
9. CAD_DrawingBoM_Table_Schema.sql
10. CAD_DrawingElement_Schema.sql
11. CAD_DrawingNote_Schema.sql
12. CAD_DrawingPMI_Schema.sql
13. CAD_DrawingSheet_Schema.sql
14. CAD_DrawingTable_Schema.sql
15. CAD_DrawingView_Schema.sql
16. CAD_Drawing_Schema.sql
17. CAD_Feature_Schema.sql
18. CAD_File_Schema.sql
19. CAD_Hole_Schema.sql
20. CAD_Interface_Schema.sql
21. CAD_Joint_Schema.sql
22. CAD_LibraryClass_Schema.sql
23. CAD_Model_Schema.sql
24. CAD_Parameter_Schema.sql
25. CAD_Part_Schema.sql
26. CAD_SketchElement_Schema.sql
27. CAD_SketchPlane_Schema.sql
28. CAD_Sketch_Schema.sql
29. CAD_Station_Schema.sql
30. CAD_Surface_Schema.sql
31. MassProperties_Schema.sql

## Usage Examples

### Inspecting the Database

After creating the database, you can inspect it using SQLite tools:

```bash
# List all tables
sqlite3 CAD_Library.db ".tables"

# Show schema for a specific table
sqlite3 CAD_Library.db ".schema CAD_Part"

# Query data (example)
sqlite3 CAD_Library.db "SELECT * FROM sqlite_master WHERE type='table' LIMIT 5;"

# Show database statistics
sqlite3 CAD_Library.db "
SELECT 
  (SELECT COUNT(*) FROM sqlite_master WHERE type='table') as tables,
  (SELECT COUNT(*) FROM sqlite_master WHERE type='view') as views,
  (SELECT COUNT(*) FROM sqlite_master WHERE type='index') as indexes;
"
```

### Programmatic Access

You can access the database from any programming language with SQLite support:

#### Python Example

```python
import sqlite3

conn = sqlite3.connect('CAD_Library.db')
cursor = conn.cursor()

# Query example
cursor.execute("SELECT name FROM CAD_Part LIMIT 10")
parts = cursor.fetchall()

for part in parts:
    print(part[0])

conn.close()
```

#### C# Example

```csharp
using System.Data.SQLite;

var connection = new SQLiteConnection("Data Source=CAD_Library.db");
connection.Open();

var command = new SQLiteCommand("SELECT name FROM CAD_Part LIMIT 10", connection);
var reader = command.ExecuteReader();

while (reader.Read())
{
    Console.WriteLine(reader["name"]);
}

connection.Close();
```

## Troubleshooting

### Database File Already Exists

The script automatically removes any existing database file before creating a new one. If you want to preserve an existing database, rename it before running the script.

### Permission Errors

Ensure you have write permissions in the directory where you're creating the database file.

### Missing SQL Files

If the script reports that SQL files are not found, verify that:
- You're running the script from the repository root directory
- The `CAD_Library/SQL/` directory exists and contains .sql files

## License

This database schema is part of the CAD_Library project. See the repository root for license information.
