#nullable enable
using System;
using System.Data;
using System.Data.SQLite;
using System.Globalization;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Strongly-typed parameter value wrapper with safe parsing and typed accessors.
    /// </summary>
    public sealed class CAD_ParameterValue
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum ParameterValueTypeEnum
        {
            Double = 0,
            Single,
            Int16,
            Int32,
            Int64,
            Boolean,
            String,
            Object
        }

        // -----------------------------
        // State
        // -----------------------------
        private object? _value;

        /// <summary>The declared type of this value.</summary>
        public ParameterValueTypeEnum ValueType { get; }

        /// <summary>The owning parameter (optional).</summary>
        public CAD_Parameter? Parameter { get; }

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_ParameterValue(ParameterValueTypeEnum type, CAD_Parameter? parameter = null)
        {
            ValueType = type;
            Parameter = parameter;
        }

        public CAD_ParameterValue(double value, CAD_Parameter? parameter = null)
            : this(ParameterValueTypeEnum.Double, parameter) => _value = value;

        public CAD_ParameterValue(float value, CAD_Parameter? parameter = null)
            : this(ParameterValueTypeEnum.Single, parameter) => _value = value;

        public CAD_ParameterValue(short value, CAD_Parameter? parameter = null)
            : this(ParameterValueTypeEnum.Int16, parameter) => _value = value;

        public CAD_ParameterValue(int value, CAD_Parameter? parameter = null)
            : this(ParameterValueTypeEnum.Int32, parameter) => _value = value;

        public CAD_ParameterValue(long value, CAD_Parameter? parameter = null)
            : this(ParameterValueTypeEnum.Int64, parameter) => _value = value;

        public CAD_ParameterValue(bool value, CAD_Parameter? parameter = null)
            : this(ParameterValueTypeEnum.Boolean, parameter) => _value = value;

        public CAD_ParameterValue(string value, CAD_Parameter? parameter = null)
            : this(ParameterValueTypeEnum.String, parameter) => _value = value;

        public CAD_ParameterValue(object value, CAD_Parameter? parameter = null)
            : this(ParameterValueTypeEnum.Object, parameter) => _value = value;

        // -----------------------------
        // Typed setters
        // -----------------------------
        public void Set(double v) { Ensure(ParameterValueTypeEnum.Double); _value = v; }
        public void Set(float v) { Ensure(ParameterValueTypeEnum.Single); _value = v; }
        public void Set(short v) { Ensure(ParameterValueTypeEnum.Int16); _value = v; }
        public void Set(int v) { Ensure(ParameterValueTypeEnum.Int32); _value = v; }
        public void Set(long v) { Ensure(ParameterValueTypeEnum.Int64); _value = v; }
        public void Set(bool v) { Ensure(ParameterValueTypeEnum.Boolean); _value = v; }
        public void Set(string v) { Ensure(ParameterValueTypeEnum.String); _value = v; }
        public void SetObject(object? v) { Ensure(ParameterValueTypeEnum.Object); _value = v; }

        /// <summary>
        /// Parses a string according to <see cref="ValueType"/> using invariant culture.
        /// Returns false if parsing fails; never throws.
        /// </summary>
        public bool TrySetFromString(string? value)
        {
            var s = value ?? string.Empty;
            var ci = CultureInfo.InvariantCulture;

            switch (ValueType)
            {
                case ParameterValueTypeEnum.Double:
                    if (double.TryParse(s, NumberStyles.Float | NumberStyles.AllowThousands, ci, out var d)) { _value = d; return true; }
                    return false;

                case ParameterValueTypeEnum.Single:
                    if (float.TryParse(s, NumberStyles.Float | NumberStyles.AllowThousands, ci, out var f)) { _value = f; return true; }
                    return false;

                case ParameterValueTypeEnum.Int16:
                    if (short.TryParse(s, NumberStyles.Integer, ci, out var i16)) { _value = i16; return true; }
                    return false;

                case ParameterValueTypeEnum.Int32:
                    if (int.TryParse(s, NumberStyles.Integer, ci, out var i32)) { _value = i32; return true; }
                    return false;

                case ParameterValueTypeEnum.Int64:
                    if (long.TryParse(s, NumberStyles.Integer, ci, out var i64)) { _value = i64; return true; }
                    return false;

                case ParameterValueTypeEnum.Boolean:
                    if (bool.TryParse(s, out var b)) { _value = b; return true; }
                    // accept 0/1 as false/true
                    if (s == "0") { _value = false; return true; }
                    if (s == "1") { _value = true; return true; }
                    return false;

                case ParameterValueTypeEnum.String:
                    _value = s;
                    return true;

                case ParameterValueTypeEnum.Object:
                    _value = s; // caller can deserialize later
                    return true;

                default:
                    return false;
            }
        }

        // -----------------------------
        // Typed getters / TryGet
        // -----------------------------
        public bool TryGetDouble(out double v) { v = 0; return ValueType == ParameterValueTypeEnum.Double && _value is double d && (v = d) == d; }
        public bool TryGetSingle(out float v) { v = 0; return ValueType == ParameterValueTypeEnum.Single && _value is float f && (v = f) == f; }
        public bool TryGetInt16(out short v) { v = 0; return ValueType == ParameterValueTypeEnum.Int16 && _value is short i16 && (v = i16) == i16; }
        public bool TryGetInt32(out int v) { v = 0; return ValueType == ParameterValueTypeEnum.Int32 && _value is int i32 && (v = i32) == i32; }
        public bool TryGetInt64(out long v) { v = 0; return ValueType == ParameterValueTypeEnum.Int64 && _value is long i64 && (v = i64) == i64; }
        public bool TryGetBoolean(out bool v) { v = false; return ValueType == ParameterValueTypeEnum.Boolean && _value is bool b && (v = b) == b; }
        public bool TryGetString(out string? v) { v = null; return ValueType == ParameterValueTypeEnum.String && _value is string s && (v = s) == s; }
        public bool TryGetObject(out object? v) { v = _value; return ValueType == ParameterValueTypeEnum.Object; }

        public double? AsDouble() => TryGetDouble(out var v) ? v : null;
        public float? AsSingle() => TryGetSingle(out var v) ? v : null;
        public short? AsInt16() => TryGetInt16(out var v) ? v : null;
        public int? AsInt32() => TryGetInt32(out var v) ? v : null;
        public long? AsInt64() => TryGetInt64(out var v) ? v : null;
        public bool? AsBoolean() => TryGetBoolean(out var v) ? v : null;
        public string? AsString() => TryGetString(out var v) ? v : null;
        public object? AsObject() => ValueType == ParameterValueTypeEnum.Object ? _value : null;

        // -----------------------------
        // Utilities
        // -----------------------------
        private void Ensure(ParameterValueTypeEnum expected)
        {
            if (ValueType != expected)
                throw new InvalidOperationException($"Value type mismatch. Expected {expected} but was {ValueType}.");
        }

        public override string ToString() =>
            ValueType switch
            {
                ParameterValueTypeEnum.Double => AsDouble()?.ToString("G", CultureInfo.InvariantCulture) ?? "null",
                ParameterValueTypeEnum.Single => AsSingle()?.ToString("G", CultureInfo.InvariantCulture) ?? "null",
                ParameterValueTypeEnum.Int16 => AsInt16()?.ToString(CultureInfo.InvariantCulture) ?? "null",
                ParameterValueTypeEnum.Int32 => AsInt32()?.ToString(CultureInfo.InvariantCulture) ?? "null",
                ParameterValueTypeEnum.Int64 => AsInt64()?.ToString(CultureInfo.InvariantCulture) ?? "null",
                ParameterValueTypeEnum.Boolean => AsBoolean()?.ToString() ?? "null",
                ParameterValueTypeEnum.String => AsString() ?? "null",
                ParameterValueTypeEnum.Object => _value?.ToString() ?? "null",
                _ => "null"
            };

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_ParameterValue? FromJson(string json) => JsonConvert.DeserializeObject<CAD_ParameterValue>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_ParameterValue"/> from a SQLite database whose schema matches
        /// the <c>CAD_ParameterValue</c> table in <c>CAD_Parameter_Schema.sql</c>.
        /// </summary>
        public static CAD_ParameterValue? FromSql(SQLiteConnection connection, string parameterValueId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(parameterValueId)) throw new ArgumentException("Parameter value ID must not be empty.", nameof(parameterValueId));

            const string query =
                "SELECT ParameterValueID, ValueType, " +
                "       DoubleValue, SingleValue, Int16Value, Int32Value, Int64Value, " +
                "       BooleanValue, StringValue, ObjectValue " +
                "FROM CAD_ParameterValue WHERE ParameterValueID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", parameterValueId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            var valueType = (ParameterValueTypeEnum)Convert.ToInt32(reader["ValueType"]);

            return valueType switch
            {
                ParameterValueTypeEnum.Double => new CAD_ParameterValue(
                    reader["DoubleValue"] is not DBNull ? Convert.ToDouble(reader["DoubleValue"]) : 0.0),
                ParameterValueTypeEnum.Single => new CAD_ParameterValue(
                    reader["SingleValue"] is not DBNull ? (float)Convert.ToDouble(reader["SingleValue"]) : 0f),
                ParameterValueTypeEnum.Int16 => new CAD_ParameterValue(
                    reader["Int16Value"] is not DBNull ? (short)Convert.ToInt32(reader["Int16Value"]) : (short)0),
                ParameterValueTypeEnum.Int32 => new CAD_ParameterValue(
                    reader["Int32Value"] is not DBNull ? Convert.ToInt32(reader["Int32Value"]) : 0),
                ParameterValueTypeEnum.Int64 => new CAD_ParameterValue(
                    reader["Int64Value"] is not DBNull ? Convert.ToInt64(reader["Int64Value"]) : 0L),
                ParameterValueTypeEnum.Boolean => new CAD_ParameterValue(
                    reader["BooleanValue"] is not DBNull && Convert.ToInt32(reader["BooleanValue"]) != 0),
                ParameterValueTypeEnum.String => new CAD_ParameterValue(
                    reader["StringValue"] as string ?? ""),
                ParameterValueTypeEnum.Object => new CAD_ParameterValue(
                    (object)(reader["ObjectValue"] as string ?? "")),
                _ => new CAD_ParameterValue(valueType)
            };
        }
    }
}
