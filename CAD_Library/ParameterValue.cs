#nullable enable
using System;
using System.Globalization;
using SE_Library;
using Mathematics;

namespace CAD
{
    /// <summary>
    /// Represents the typed value of a CAD parameter.
    /// Refactored from CAD_ParameterValue to ParameterValue.
    /// </summary>
    public class ParameterValue
    {
        // -----------------------------
        // Enumerations
        // -----------------------------
        public enum ParameterValueTypeEnum
        {
            Double = 0,
            Single,
            Int,
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
        private object? _boxedValue;

        // -----------------------------
        // Constructors
        // -----------------------------
        public ParameterValue(ParameterValueTypeEnum type, Parameter parameter)
        {
            MyValueType = type;
            MyParameter = parameter ?? throw new ArgumentNullException(nameof(parameter));
        }

        // -----------------------------
        // Properties (added)
        // -----------------------------

        /// <summary>The declared value kind for this parameter value.</summary>
        public ParameterValueTypeEnum MyValueType { get; }

        /// <summary>The owning parameter.</summary>
        public Parameter MyParameter { get; set; }

        /// <summary>
        /// The stored value as an <see cref="object"/>. Setting validates the runtime type
        /// against <see cref="MyValueType"/> (except for <see cref="ParameterValueTypeEnum.Object"/>).
        /// </summary>
        public object? BoxedValue
        {
            get => _boxedValue;
            set
            {
                if (!IsCompatible(value))
                    throw new ArgumentException(
                        $"Value of type '{value?.GetType().Name ?? "null"}' is not compatible with '{MyValueType}'.",
                        nameof(value));
                _boxedValue = value;
            }
        }

        // Strongly-typed convenience accessors (null if not compatible or not set)
        public double? DoubleValue { get => _boxedValue as double?; set => SetTyped(value, ParameterValueTypeEnum.Double); }
        public float? SingleValue { get => _boxedValue as float?; set => SetTyped(value, ParameterValueTypeEnum.Single); }
        public int? IntValue { get => _boxedValue as int?; set => SetTyped(value, ParameterValueTypeEnum.Int); }
        public short? Int16Value { get => _boxedValue as short?; set => SetTyped(value, ParameterValueTypeEnum.Int16); }
        public int? Int32Value { get => _boxedValue as int?; set => SetTyped(value, ParameterValueTypeEnum.Int32); }
        public long? Int64Value { get => _boxedValue as long?; set => SetTyped(value, ParameterValueTypeEnum.Int64); }
        public bool? BooleanValue { get => _boxedValue as bool?; set => SetTyped(value, ParameterValueTypeEnum.Boolean); }
        public string? StringValue { get => _boxedValue as string; set => SetTyped(value, ParameterValueTypeEnum.String); }

        /// <summary>
        /// Returns the value formatted as a string using the provided format/culture
        /// (numeric types respect <paramref name="provider"/>).
        /// </summary>
        public string ToDisplayString(IFormatProvider? provider = null, string? numericFormat = null)
        {
            provider ??= CultureInfo.InvariantCulture;
            return MyValueType switch
            {
                ParameterValueTypeEnum.Double => Format(DoubleValue, numericFormat, provider),
                ParameterValueTypeEnum.Single => Format(SingleValue, numericFormat, provider),
                ParameterValueTypeEnum.Int => (IntValue?.ToString(provider) ?? string.Empty),
                ParameterValueTypeEnum.Int16 => (Int16Value?.ToString(provider) ?? string.Empty),
                ParameterValueTypeEnum.Int32 => (Int32Value?.ToString(provider) ?? string.Empty),
                ParameterValueTypeEnum.Int64 => (Int64Value?.ToString(provider) ?? string.Empty),
                ParameterValueTypeEnum.Boolean => (BooleanValue?.ToString(provider) ?? string.Empty),
                ParameterValueTypeEnum.String => (StringValue ?? string.Empty),
                ParameterValueTypeEnum.Object => BoxedValue?.ToString() ?? string.Empty,
                _ => BoxedValue?.ToString() ?? string.Empty
            };

            static string Format<T>(T? v, string? fmt, IFormatProvider p) where T : struct, IFormattable
                => v.HasValue ? v.Value.ToString(fmt, p) : string.Empty;
        }

        // -----------------------------
        // Parsing / setting helpers
        // -----------------------------

        /// <summary>Set the value by parsing a string according to <see cref="MyValueType"/>.</summary>
        public void SetFromString(string? text, IFormatProvider? provider = null)
        {
            provider ??= CultureInfo.InvariantCulture;

            switch (MyValueType)
            {
                case ParameterValueTypeEnum.Double:
                    BoxedValue = string.IsNullOrWhiteSpace(text) ? null : double.Parse(text, provider);
                    break;
                case ParameterValueTypeEnum.Single:
                    BoxedValue = string.IsNullOrWhiteSpace(text) ? null : float.Parse(text!, provider);
                    break;
                case ParameterValueTypeEnum.Int:
                    BoxedValue = string.IsNullOrWhiteSpace(text) ? null : int.Parse(text!, NumberStyles.Integer, provider);
                    break;
                case ParameterValueTypeEnum.Int16:
                    BoxedValue = string.IsNullOrWhiteSpace(text) ? null : short.Parse(text!, NumberStyles.Integer, provider);
                    break;
                case ParameterValueTypeEnum.Int32:
                    BoxedValue = string.IsNullOrWhiteSpace(text) ? null : int.Parse(text!, NumberStyles.Integer, provider);
                    break;
                case ParameterValueTypeEnum.Int64:
                    BoxedValue = string.IsNullOrWhiteSpace(text) ? null : long.Parse(text!, NumberStyles.Integer, provider);
                    break;
                case ParameterValueTypeEnum.Boolean:
                    BoxedValue = string.IsNullOrWhiteSpace(text) ? null : bool.Parse(text!);
                    break;
                case ParameterValueTypeEnum.String:
                    BoxedValue = text ?? string.Empty;
                    break;
                case ParameterValueTypeEnum.Object:
                    // Caller must assign BoxedValue directly for complex objects
                    BoxedValue = text;
                    break;
                default:
                    throw new NotSupportedException($"Unsupported value type: {MyValueType}");
            }
        }

        /// <summary>Try get the value strongly-typed.</summary>
        public bool TryGet<T>(out T? value)
        {
            if (_boxedValue is T t)
            {
                value = t;
                return true;
            }
            value = default;
            return false;
        }

        public override string ToString() => ToDisplayString();

        // -----------------------------
        // Internal helpers
        // -----------------------------
        private bool IsCompatible(object? value)
        {
            if (value is null) return true; // allow clearing

            return MyValueType switch
            {
                ParameterValueTypeEnum.Double => value is double,
                ParameterValueTypeEnum.Single => value is float,
                ParameterValueTypeEnum.Int => value is int,
                ParameterValueTypeEnum.Int16 => value is short,
                ParameterValueTypeEnum.Int32 => value is int,
                ParameterValueTypeEnum.Int64 => value is long,
                ParameterValueTypeEnum.Boolean => value is bool,
                ParameterValueTypeEnum.String => value is string,
                ParameterValueTypeEnum.Object => true,
                _ => false
            };
        }

        private void SetTyped<T>(T? val, ParameterValueTypeEnum expected) where T : struct
        {
            if (MyValueType != expected && MyValueType != ParameterValueTypeEnum.Object)
                throw new InvalidOperationException($"Attempt to set {expected} while declared type is {MyValueType}.");

            BoxedValue = val;
        }

        private void SetTyped(string? val, ParameterValueTypeEnum expected)
        {
            if (MyValueType != expected && MyValueType != ParameterValueTypeEnum.Object)
                throw new InvalidOperationException($"Attempt to set {expected} while declared type is {MyValueType}.");

            BoxedValue = val;
        }
    }
}
