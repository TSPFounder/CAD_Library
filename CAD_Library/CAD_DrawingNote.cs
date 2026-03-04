
using System;
using System.Data;
using System.Data.SQLite;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Simple POCO representing a drawing note with an ID, text, and categorical type.
    /// </summary>
    public class CAD_DrawingNote
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum NoteType
        {
            General = 0,
            Safety,
            Process,
            Material,
            Finish,
            Reference,
            Tolerance,
            Other
        }

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_DrawingNote() { }

        public CAD_DrawingNote(string? id, string? text, NoteType type = NoteType.General)
        {
            DrawingNoteID = id;
            NoteText = text;
            MyNoteType = type;
        }

        // -----------------------------
        // Properties
        // -----------------------------
        /// <summary>Unique identifier for the note (optional).</summary>
        public string? DrawingNoteID { get; set; }

        /// <summary>Displayed note text (may be multi-line).</summary>
        public string? NoteText { get; set; }

        /// <summary>Category of the note to aid filtering/searching.</summary>
        public NoteType MyNoteType { get; set; } = NoteType.General;

        // -----------------------------
        // Helpers
        // -----------------------------
        /// <summary>Returns true if the note has no visible text.</summary>
        public bool IsEmpty() => string.IsNullOrWhiteSpace(NoteText);

        /// <summary>Updates note text, trimming leading/trailing whitespace.</summary>
        public void SetText(string? text) => NoteText = text?.Trim();

        public override string ToString()
            => string.IsNullOrWhiteSpace(NoteText)
                ? $"[{MyNoteType}] (empty)"
                : $"[{MyNoteType}] {NoteText}";

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_DrawingNote? FromJson(string json) => JsonConvert.DeserializeObject<CAD_DrawingNote>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingNote"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingNote_Schema.sql</c>.
        /// </summary>
        public static CAD_DrawingNote? FromSql(SQLiteConnection connection, string drawingNoteId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(drawingNoteId)) throw new ArgumentException("Drawing note ID must not be empty.", nameof(drawingNoteId));

            const string query =
                "SELECT DrawingNoteID, NoteText, MyNoteType " +
                "FROM CAD_DrawingNote WHERE DrawingNoteID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", drawingNoteId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_DrawingNote
            {
                DrawingNoteID = reader["DrawingNoteID"] as string,
                NoteText = reader["NoteText"] as string,
                MyNoteType = (NoteType)Convert.ToInt32(reader["MyNoteType"])
            };
        }
    }
}

