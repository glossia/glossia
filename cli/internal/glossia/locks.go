package glossia

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"
)

type OutputLock struct {
	Path        string `json:"path"`
	Hash        string `json:"hash"`
	ContextHash string `json:"context_hash,omitempty"`
	CheckedAt   string `json:"checked_at"`
}

type LockFile struct {
	SourcePath  string                `json:"source_path"`
	SourceHash  string                `json:"source_hash"`
	ContextHash string                `json:"context_hash,omitempty"`
	Outputs     map[string]OutputLock `json:"outputs"`
	UpdatedAt   string                `json:"updated_at"`
}

func createLock(sourcePath string) LockFile {
	return LockFile{
		SourcePath: sourcePath,
		SourceHash: "",
		Outputs:    map[string]OutputLock{},
		UpdatedAt:  "",
	}
}

func lockPath(root string, sourcePath string) string {
	return filepath.Join(root, ".glossia", "locks", sourcePath+".lock")
}

func readLock(root string, sourcePath string) (*LockFile, error) {
	filePath := lockPath(root, sourcePath)

	raw, err := os.ReadFile(filePath)
	if err != nil {
		return nil, nil
	}

	var lock LockFile
	if err := json.Unmarshal(raw, &lock); err != nil {
		return nil, nil
	}
	return &lock, nil
}

func writeLock(root string, sourcePath string, lock *LockFile) error {
	lock.UpdatedAt = nowISO()

	filePath := lockPath(root, sourcePath)
	if err := os.MkdirAll(filepath.Dir(filePath), 0o755); err != nil {
		return err
	}

	encoded, err := json.MarshalIndent(lock, "", "  ")
	if err != nil {
		return err
	}
	encoded = append(encoded, '\n')

	return os.WriteFile(filePath, encoded, 0o644)
}

func nowISO() string {
	// Match JS Date.toISOString() millisecond precision.
	return time.Now().UTC().Format("2006-01-02T15:04:05.000Z")
}
