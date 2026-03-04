
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using CAD;
using Mathematics;
using SE_Library;
using System.IO;
using System.Reflection.PortableExecutable;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Describes a CAD content library (e.g., parts/templates) that may live
    /// on a local/network path and/or be reachable via a URL.
    /// </summary>
    public sealed class CAD_Library
    {
        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_Library() { }

        public CAD_Library(string? name, string? localPath = null, Uri? url = null, string? description = null)
        {
            Name = name;
            Description = description;
            LocalPath = localPath;
            Url = url;
        }

        /// <summary>Create with a URL string (parsed to <see cref="Uri"/>).</summary>
        public static CAD_Library FromUrl(string? name, string url, string? description = null)
            => new(name, url: ParseUri(url), description: description);

        // -----------------------------
        // Identity / metadata
        // -----------------------------
        public string? Name { get; set; }
        public string? Description { get; set; }

        /// <summary>Local or network location (may be relative or absolute).</summary>
        public string? LocalPath { get; set; }

        /// <summary>Remote location (HTTP(S), share URL, etc.).</summary>
        public Uri? Url { get; set; }

        // -----------------------------
        // Derived state
        // -----------------------------
        public bool HasLocalPath => !string.IsNullOrWhiteSpace(LocalPath);
        public bool HasRemoteUrl => Url is not null;

        /// <summary>True if at least a name and one location (local or remote) is provided.</summary>
        public bool IsConfigured
            => !string.IsNullOrWhiteSpace(Name) && (HasLocalPath || HasRemoteUrl);

        // -----------------------------
        // Helpers
        // -----------------------------
        /// <summary>
        /// Returns an absolute local path if <see cref="LocalPath"/> is set; otherwise null.
        /// Does not check existence.
        /// </summary>
        public string? GetAbsoluteLocalPath()
        {
            if (!HasLocalPath) return null;
            try { return Path.GetFullPath(LocalPath!); }
            catch { return null; }
        }

        /// <summary>Attempt to set <see cref="Url"/> from a string. Returns false on parse error.</summary>
        public bool TrySetUrl(string? url)
        {
            if (string.IsNullOrWhiteSpace(url)) { Url = null; return true; }
            if (Uri.TryCreate(url, UriKind.Absolute, out var uri) && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps))
            {
                Url = uri;
                return true;
            }
            return false;
        }

        /// <summary>Validate minimal configuration. Returns true if OK, with reason when invalid.</summary>
        public bool IsValid(out string? reason)
        {
            if (string.IsNullOrWhiteSpace(Name))
            {
                reason = "Library must have a Name.";
                return false;
            }

            if (!HasLocalPath && !HasRemoteUrl)
            {
                reason = "Library must specify a LocalPath and/or a Url.";
                return false;
            }

            reason = null;
            return true;
        }

        public override string ToString()
            => $"{Name ?? "(unnamed)"} | Local: {LocalPath ?? "-"} | Url: {Url?.ToString() ?? "-"}";

        // -----------------------------
        // Internal
        // -----------------------------
        private static Uri ParseUri(string url)
        {
            if (!Uri.TryCreate(url, UriKind.Absolute, out var uri))
                throw new ArgumentException("Invalid URL.", nameof(url));
            return uri;
        }

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_Library? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Library>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Library"/> from a SQLite database whose schema matches
        /// <c>CAD_LibraryClass_Schema.sql</c>.
        /// </summary>
        public static CAD_Library? FromSql(SQLiteConnection connection, string libraryId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(libraryId)) throw new ArgumentException("Library ID must not be empty.", nameof(libraryId));

            const string query =
                "SELECT LibraryID, Name, Description, LocalPath, Url " +
                "FROM CAD_Library WHERE LibraryID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", libraryId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            string? urlStr = reader["Url"] as string;

            return new CAD_Library
            {
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                LocalPath = reader["LocalPath"] as string,
                Url = urlStr != null ? new Uri(urlStr) : null
            };
        }
    }
}
