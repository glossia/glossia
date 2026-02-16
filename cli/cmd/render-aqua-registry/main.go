package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	var baseURL string
	var output string

	flag.StringVar(&baseURL, "base-url", "", "")
	flag.StringVar(&output, "output", "", "")
	flag.Parse()

	if strings.TrimSpace(baseURL) == "" {
		fail("--base-url is required")
	}
	if strings.TrimSpace(output) == "" {
		fail("--output is required")
	}

	normalized := strings.TrimRight(baseURL, "/")

	content := fmt.Sprintf(`# yaml-language-server: $schema=https://raw.githubusercontent.com/aquaproj/aqua/main/json-schema/registry.json
packages:
  - type: http
    repo_owner: glossia
    repo_name: glossia
    description: Localize like you ship software
    version_source: github_tag
    version_filter: not (Version contains "-")
    url: %s/{{.Version}}/glossia-{{.OS}}-{{.Arch}}.{{.Format}}
    format: tar.gz
    files:
      - name: glossia
        src: glossia
    replacements:
      amd64: x64
    overrides:
      - goos: windows
        format: zip
        files:
          - name: glossia
            src: glossia.exe
        supported_envs:
          - windows
          - amd64
    checksum:
      type: http
      url: %s/{{.Version}}/SHA256SUMS
      algorithm: sha256
    supported_envs:
      - darwin
      - linux
      - amd64
      - arm64
`, normalized, normalized)

	if err := os.MkdirAll(filepath.Dir(output), 0o755); err != nil {
		fail(err.Error())
	}
	if err := os.WriteFile(output, []byte(content), 0o644); err != nil {
		fail(err.Error())
	}

	fmt.Printf("wrote Aqua registry config to %s\n", output)
}

func fail(msg string) {
	fmt.Fprintln(os.Stderr, msg)
	os.Exit(1)
}
