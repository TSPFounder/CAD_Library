
using System;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using SE_Library;
using Documents;
using Newtonsoft.Json;

namespace CAD
{
    public class CAD_Configuration
    {
        // -----------------------------
        // Constructor
        // -----------------------------
        public CAD_Configuration() { }

        // -----------------------------
        // Identification
        // -----------------------------
        public string? Name { get; set; }
        public string? Description { get; set; }
        public string? ID { get; set; }
        public string? Revision { get; set; }

        // -----------------------------
        // Owned & Owning Objects
        // -----------------------------
        public CAD_Part? CurrentPart { get; set; }
        public SE_TableRow? CurrentPartRow { get; set; }   // surfaced from original field
        public CAD_Assembly? MyAssembly { get; set; }

        // -----------------------------
        // Diagnostics
        // -----------------------------
        public override string ToString()
            => $"CAD_Configuration(Name={Name ?? "<null>"}, ID={ID ?? "<null>"}, Rev={Revision ?? "<null>"})";

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_Configuration? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Configuration>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Configuration"/> from a SQLite database whose schema matches
        /// <c>CAD_Configuration_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="configurationId">The <c>ConfigurationID</c> value of the configuration row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_Configuration"/>, or <c>null</c> if the ID was not found.</returns>
        public static CAD_Configuration? FromSql(SQLiteConnection connection, string configurationId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(configurationId)) throw new ArgumentException("Configuration ID must not be empty.", nameof(configurationId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Configuration row
            // ----------------------------------------------------------
            const string configQuery =
                "SELECT ConfigurationID, Name, Description, Revision, " +
                "       CurrentPartID, CurrentPartRowID, MyAssemblyID " +
                "FROM CAD_Configuration WHERE ConfigurationID = @id;";

            CAD_Configuration? config = null;
            string? partId = null;
            string? partRowId = null;
            string? assemblyId = null;

            using (var cmd = new SQLiteCommand(configQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", configurationId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                config = new CAD_Configuration
                {
                    ID = reader["ConfigurationID"] as string,
                    Name = reader["Name"] as string,
                    Description = reader["Description"] as string,
                    Revision = reader["Revision"] as string
                };

                partId = reader["CurrentPartID"] as string;
                partRowId = reader["CurrentPartRowID"] as string;
                assemblyId = reader["MyAssemblyID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load CurrentPart
            // ----------------------------------------------------------
            if (partId != null)
            {
                config.CurrentPart = LoadPart(connection, partId);
            }

            // ----------------------------------------------------------
            // 3. Load CurrentPartRow (SE_TableRow)
            // ----------------------------------------------------------
            if (partRowId != null)
            {
                config.CurrentPartRow = LoadTableRow(connection, partRowId);
            }

            // ----------------------------------------------------------
            // 4. Load MyAssembly
            // ----------------------------------------------------------
            if (assemblyId != null)
            {
                config.MyAssembly = LoadAssembly(connection, assemblyId);
            }

            return config;
        }

        // -----------------------------
        // Private SQL helpers
        // -----------------------------

        private static CAD_Part? LoadPart(SQLiteConnection connection, string partId)
        {
            const string query =
                "SELECT PartID, Name, Version, PartNumber, Description " +
                "FROM CAD_Part WHERE PartID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", partId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Part
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                PartNumber = reader["PartNumber"] as string,
                Description = reader["Description"] as string
            };
        }

        private static SE_TableRow? LoadTableRow(SQLiteConnection connection, string tableRowId)
        {
            const string query =
                "SELECT TableRowID, TableID " +
                "FROM SE_TableRow WHERE TableRowID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", tableRowId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            string? tableId = reader["TableID"] as string;
            SE_Table? table = tableId != null ? LoadTable(connection, tableId) : null;

            return new SE_TableRow(table!);
        }

        private static SE_Table? LoadTable(SQLiteConnection connection, string tableId)
        {
            const string query =
                "SELECT TableID, Name, Description " +
                "FROM SE_Table WHERE TableID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", tableId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new SE_Table(reader["Name"] as string ?? "");
        }

        private static CAD_Assembly? LoadAssembly(SQLiteConnection connection, string assemblyId)
        {
            const string query =
                "SELECT AssemblyID, Name, Version, Description, " +
                "       IsSubAssembly, IsConfigurationItem " +
                "FROM CAD_Assembly WHERE AssemblyID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", assemblyId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Assembly
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                Description = reader["Description"] as string,
                IsSubAssembly = Convert.ToInt32(reader["IsSubAssembly"]) != 0,
                IsConfigurationItem = Convert.ToInt32(reader["IsConfigurationItem"]) != 0
            };
        }
    }
}
