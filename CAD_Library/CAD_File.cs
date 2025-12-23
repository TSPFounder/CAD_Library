#nullable enable
using System;
using System.Collections.Generic;
using Applications;

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
    }
}