
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Applications;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Represents a CAD-centric wrapper around <see cref="AppFile"/>, tracking source application,
    /// file classification, and ownership metadata for models, parts, and drawings.
    /// </summary>
    public class CAD_File : AppFile
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum FileLocationState
        {
            Unknown = 0,
            LocalOnly,
            RemoteOnly,
            Synchronized
        }

        // -----------------------------
        // Backing fields
        // -----------------------------
        private readonly List<CAD_Configuration> _configurations = new();

        // -----------------------------
        // Constructors
        // -----------------------------
        public CAD_File() { }

        public CAD_File(string? displayName,
                        CAD_Model.CAD_FileTypeEnum fileType = CAD_Model.CAD_FileTypeEnum.other,
                        CAD_Model.CAD_AppEnum sourceApplication = CAD_Model.CAD_AppEnum.Other)
        {
            DisplayName = displayName;
            FileType = fileType;
            SourceApplication = sourceApplication;
        }

        // -----------------------------
        // Identification / metadata
        // -----------------------------
        public string? DisplayName { get; set; }
        public Version? FileVersion { get; set; }
        public CAD_Model.CAD_FileTypeEnum FileType { get; set; } = CAD_Model.CAD_FileTypeEnum.other;
        public CAD_Model.CAD_AppEnum SourceApplication { get; set; } = CAD_Model.CAD_AppEnum.Other;
        public long? FileSizeBytes { get; set; }
        public DateTimeOffset? LastModifiedUtc { get; set; }
        public FileLocationState LocationState { get; private set; } = FileLocationState.Unknown;

        // -----------------------------
        // Locations
        // -----------------------------
        public string? LocalPath { get; private set; }
        public Uri? RemoteUri { get; private set; }
        public bool HasLocalCopy => !string.IsNullOrWhiteSpace(LocalPath);
        public bool HasRemoteCopy => RemoteUri is not null;

        // -----------------------------
        // Owned & owning objects
        // -----------------------------
        public CAD_Model? OwningModel { get; set; }
        public CAD_Part? OwningPart { get; set; }
        public CAD_Drawing? OwningDrawing { get; set; }
        public CAD_DrawingElement? SourceElement { get; set; }
        public IReadOnlyList<CAD_Configuration> Configurations => _configurations;

        // -----------------------------
        // Mutators
        // -----------------------------
        public void SetLocalPath(string? path)
        {
            LocalPath = string.IsNullOrWhiteSpace(path) ? null : path;
            UpdateLocationState();
        }

        public void SetRemoteUri(Uri? uri)
        {
            RemoteUri = uri;
            UpdateLocationState();
        }

        public void AddConfiguration(CAD_Configuration configuration)
        {
            if (configuration is null) throw new ArgumentNullException(nameof(configuration));
            _configurations.Add(configuration);
        }

        public void MarkSynchronized(DateTimeOffset timestampUtc, long? fileSizeBytes = null)
        {
            LastModifiedUtc = timestampUtc;
            if (fileSizeBytes.HasValue) FileSizeBytes = fileSizeBytes;
            UpdateLocationState();
        }

        // -----------------------------
        // Helpers
        // -----------------------------
        private void UpdateLocationState()
        {
            LocationState = (HasLocalCopy, HasRemoteCopy) switch
            {
                (true, true) => FileLocationState.Synchronized,
                (true, false) => FileLocationState.LocalOnly,
                (false, true) => FileLocationState.RemoteOnly,
                _ => FileLocationState.Unknown
            };
        }

        public override string ToString()
            => $"CAD_File(Name={DisplayName ?? "<null>"}, Type={FileType}, App={SourceApplication}, State={LocationState})";

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_File? FromJson(string json) => JsonConvert.DeserializeObject<CAD_File>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_File"/> from a SQLite database whose schema matches
        /// <c>CAD_File_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="fileId">The <c>FileID</c> value of the file row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_File"/>, or <c>null</c> if the ID was not found.</returns>
        public static CAD_File? FromSql(SQLiteConnection connection, string fileId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(fileId)) throw new ArgumentException("File ID must not be empty.", nameof(fileId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_File row
            // ----------------------------------------------------------
            const string fileQuery =
                "SELECT FileID, DisplayName, FileVersion, FileType, SourceApplication, " +
                "       FileSizeBytes, LastModifiedUtc, LocalPath, RemoteUri, " +
                "       OwningModelID, OwningPartID, OwningDrawingID, SourceElementID " +
                "FROM CAD_File WHERE FileID = @id;";

            CAD_File? file = null;
            string? owningModelId = null;
            string? owningPartId = null;
            string? owningDrawingId = null;
            string? sourceElementId = null;

            using (var cmd = new SQLiteCommand(fileQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", fileId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                file = new CAD_File
                {
                    DisplayName = reader["DisplayName"] as string,
                    FileType = (CAD_Model.CAD_FileTypeEnum)Convert.ToInt32(reader["FileType"]),
                    SourceApplication = (CAD_Model.CAD_AppEnum)Convert.ToInt32(reader["SourceApplication"])
                };

                // FileVersion
                string? versionStr = reader["FileVersion"] as string;
                if (versionStr != null && System.Version.TryParse(versionStr, out var parsedVersion))
                {
                    file.FileVersion = parsedVersion;
                }

                // FileSizeBytes
                if (reader["FileSizeBytes"] is not DBNull)
                {
                    file.FileSizeBytes = Convert.ToInt64(reader["FileSizeBytes"]);
                }

                // LastModifiedUtc
                string? lastModStr = reader["LastModifiedUtc"] as string;
                if (lastModStr != null && DateTimeOffset.TryParse(lastModStr, out var lastMod))
                {
                    file.LastModifiedUtc = lastMod;
                }

                // Locations
                string? localPath = reader["LocalPath"] as string;
                if (localPath != null) file.SetLocalPath(localPath);

                string? remoteUriStr = reader["RemoteUri"] as string;
                if (remoteUriStr != null) file.SetRemoteUri(new Uri(remoteUriStr));

                owningModelId = reader["OwningModelID"] as string;
                owningPartId = reader["OwningPartID"] as string;
                owningDrawingId = reader["OwningDrawingID"] as string;
                sourceElementId = reader["SourceElementID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load OwningModel
            // ----------------------------------------------------------
            if (owningModelId != null)
            {
                file.OwningModel = LoadModel(connection, owningModelId);
            }

            // ----------------------------------------------------------
            // 3. Load OwningPart
            // ----------------------------------------------------------
            if (owningPartId != null)
            {
                file.OwningPart = LoadPart(connection, owningPartId);
            }

            // ----------------------------------------------------------
            // 4. Load OwningDrawing
            // ----------------------------------------------------------
            if (owningDrawingId != null)
            {
                file.OwningDrawing = LoadDrawing(connection, owningDrawingId);
            }

            // ----------------------------------------------------------
            // 5. Load SourceElement
            // ----------------------------------------------------------
            if (sourceElementId != null)
            {
                file.SourceElement = LoadDrawingElement(connection, sourceElementId);
            }

            // ----------------------------------------------------------
            // 6. Load Configurations from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_File_Configuration", "FileID", fileId, "ConfigurationID",
                id =>
                {
                    var config = LoadConfiguration(connection, id);
                    if (config != null) file.AddConfiguration(config);
                });

            return file;
        }

        // -----------------------------
        // Private SQL helpers
        // -----------------------------

        private static void LoadJunction(SQLiteConnection connection, string tableName,
            string ownerColumn, string ownerId, string childColumn, Action<string> onChildId)
        {
            string query = $"SELECT {childColumn} FROM {tableName} " +
                           $"WHERE {ownerColumn} = @id ORDER BY SortOrder;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", ownerId);
            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                string childId = reader[childColumn] as string ?? "";
                onChildId(childId);
            }
        }

        private static CAD_Model? LoadModel(SQLiteConnection connection, string modelId)
        {
            const string query =
                "SELECT ModelID, Name, Version, Description, FilePath, " +
                "       CAD_AppName, ModelType, FileType " +
                "FROM CAD_Model WHERE ModelID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", modelId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Model
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                Description = reader["Description"] as string,
                FilePath = reader["FilePath"] as string,
                CAD_AppName = (CAD_Model.CAD_AppEnum)Convert.ToInt32(reader["CAD_AppName"]),
                ModelType = (CAD_Model.CAD_ModelTypeEnum)Convert.ToInt32(reader["ModelType"]),
                FileType = (CAD_Model.CAD_FileTypeEnum)Convert.ToInt32(reader["FileType"])
            };
        }

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

        private static CAD_Drawing? LoadDrawing(SQLiteConnection connection, string drawingId)
        {
            const string query =
                "SELECT DrawingID, Title, DrawingNumber, Revision " +
                "FROM CAD_Drawing WHERE DrawingID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", drawingId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Drawing
            {
                Title = reader["Title"] as string,
                DrawingNumber = reader["DrawingNumber"] as string,
                Revision = reader["Revision"] as string
            };
        }

        private static CAD_DrawingElement? LoadDrawingElement(SQLiteConnection connection, string elementId)
        {
            const string query =
                "SELECT DrawingElementID, Name, MyType " +
                "FROM CAD_DrawingElement WHERE DrawingElementID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", elementId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_DrawingElement
            {
                Name = reader["Name"] as string,
                MyType = (CAD_DrawingElement.DrawingElementType)Convert.ToInt32(reader["MyType"])
            };
        }

        private static CAD_Configuration? LoadConfiguration(SQLiteConnection connection, string configId)
        {
            const string query =
                "SELECT ConfigurationID, Name, Description, Revision " +
                "FROM CAD_Configuration WHERE ConfigurationID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", configId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Configuration
            {
                ID = reader["ConfigurationID"] as string,
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                Revision = reader["Revision"] as string
            };
        }
    }
}