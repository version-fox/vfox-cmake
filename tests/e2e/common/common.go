// Copyright 2026 Han Li and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Package common holds the constants and Docker helpers shared by the Linux
// and Windows E2E suites. The suites deliberately use only the standard
// library and drive the `docker` CLI, so they run on any host with Docker
// without a large dependency tree.
package common

import (
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"testing"
	"time"
)

const (
	// VfoxVersion is pinned to the first release with the Detect hook.
	VfoxVersion = "1.1.0"
	// VfoxSha256 is the digest of vfox_1.1.0_linux_x86_64.tar.gz.
	VfoxSha256 = "3b33c3c468b27bc17aecf0d6d3af24fe49fe204972984904a136a47b402a0ee4"
	// CMakeVersion is the release installed by the E2E suites. It is present
	// in assets/version.json for every platform the plugin supports.
	CMakeVersion = "3.31.6"
	// DetectVersion is the version reported by the stub CMake the suites put
	// on PATH to exercise `vfox link --detect cmake`. It differs from the
	// installed release so the two never collapse into one linked version.
	DetectVersion = "3.20.0"
	// ImagePrefix names the images the suites build.
	ImagePrefix = "vfox-cmake-e2e"
)

var ansiEscape = regexp.MustCompile(`\x1b\[[0-9;]*m`)

// StripANSI removes the SGR colour sequences vfox writes even to a pipe.
func StripANSI(s string) string {
	return ansiEscape.ReplaceAllString(s, "")
}

// Run executes a docker command and returns its combined output.
func Run(args ...string) (string, error) {
	cmd := exec.Command("docker", args...)
	out, err := cmd.CombinedOutput()
	return string(out), err
}

// Exec runs a command inside a container and returns its combined output.
func Exec(container string, args ...string) (string, error) {
	return Run(append([]string{"exec", container}, args...)...)
}

// ExecOK is Exec but fails the test with the output when the command fails.
func ExecOK(t *testing.T, container string, args ...string) string {
	t.Helper()
	out, err := Exec(container, args...)
	if err != nil {
		t.Fatalf("docker exec %v: %v\n--- output ---\n%s", args, err, out)
	}
	return StripANSI(out)
}

// AssertContains fails t unless output holds want. The context names what was
// checked, so a failure says which phase of the suite broke.
func AssertContains(t *testing.T, output, want, context string) {
	t.Helper()
	if !strings.Contains(StripANSI(output), want) {
		t.Fatalf("%s: output does not contain %q\n--- output ---\n%s", context, want, output)
	}
}

// ContainerName returns a unique name per run: the slug stays greppable in
// `docker ps`, the suffix avoids clashes with leftovers from killed runs.
func ContainerName(slug string) string {
	return fmt.Sprintf("%s-%s-%d-%d", ImagePrefix, slug, os.Getpid(), time.Now().UnixNano())
}
