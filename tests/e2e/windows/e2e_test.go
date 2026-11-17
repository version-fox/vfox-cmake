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

// Package windows is the Windows container E2E suite. It builds the image in
// tests/e2e/windows/Dockerfile once and drives setup, install, exec and
// Detect through `docker exec` calls. The suite runs on a Windows host with
// Windows container support (windows-latest in CI).
package windows

import (
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	"github.com/version-fox/vfox-cmake/tests/e2e/common"
)

func TestE2E(t *testing.T) {
	if testing.Short() {
		t.Skip("skip container E2E in short mode")
	}
	if runtime.GOOS != "windows" {
		t.Skip("the Windows E2E suite requires a Windows host with Docker")
	}

	image := common.ImagePrefix + ":windows"
	repoRoot, err := filepath.Abs(filepath.Join("..", "..", ".."))
	if err != nil {
		t.Fatal(err)
	}
	dockerfile, err := filepath.Abs("Dockerfile")
	if err != nil {
		t.Fatal(err)
	}
	if out, err := common.Run("build", "--file", dockerfile, "--tag", image, repoRoot); err != nil {
		t.Fatalf("build image: %v\n--- output ---\n%s", err, out)
	}

	name := common.ContainerName("windows")
	if out, err := common.Run("run", "--detach", "--name", name, image); err != nil {
		t.Fatalf("start container: %v\n--- output ---\n%s", err, out)
	}
	t.Cleanup(func() {
		_, _ = common.Run("rm", "--force", name)
	})

	version := common.ExecOK(t, name, "vfox", "--version")
	common.AssertContains(t, version, common.VfoxVersion, "vfox version")

	search := common.ExecOK(t, name, "vfox", "search", "cmake")
	common.AssertContains(t, search, common.CMakeVersion, "search lists the pinned release")

	install := installCMake(t, name)
	common.AssertContains(t, install, "Install cmake@"+common.CMakeVersion+" success!", "install")

	executed := common.ExecOK(t, name, "vfox", "exec", "cmake@"+common.CMakeVersion, "--", "cmake", "--version")
	common.AssertContains(t, executed, "cmake version "+common.CMakeVersion, "vfox exec runs the installed CMake")

	verifyDetect(t, name)
}

// installCMake installs the pinned release, retrying a few times because the
// download comes from cmake.org and a transient network error should not make
// the whole suite fail.
func installCMake(t *testing.T, name string) string {
	t.Helper()
	for attempt := 1; attempt <= 5; attempt++ {
		out, err := common.Exec(name, "vfox", "install", "cmake@"+common.CMakeVersion)
		if err == nil && strings.Contains(common.StripANSI(out), "success!") {
			return common.StripANSI(out)
		}
		t.Logf("install attempt %d failed: %v\n--- output ---\n%s", attempt, err, out)
	}
	t.Fatal("vfox install cmake@" + common.CMakeVersion + " failed after 5 attempts")
	return ""
}

// verifyDetect builds a tiny stub CMake on the host, copies it into the
// container on PATH, and checks that vfox link --detect finds and links it.
func verifyDetect(t *testing.T, name string) {
	t.Helper()
	exe := buildStub(t)
	common.ExecOK(t, name, "powershell", "-NoProfile", "-Command",
		"New-Item -ItemType Directory -Force -Path C:\\fake-cmake\\bin | Out-Null")
	if out, err := common.Run("cp", exe, name+":C:\\fake-cmake\\bin\\cmake.exe"); err != nil {
		t.Fatalf("copy stub into container: %v\n--- output ---\n%s", err, out)
	}

	out, err := common.Run("exec",
		"-e", "PATH=C:\\fake-cmake\\bin;C:\\Windows\\System32",
		name, "vfox", "link", "--detect", "cmake", "--yes")
	if err != nil {
		t.Fatalf("vfox link --detect: %v\n--- output ---\n%s", err, out)
	}
	linked := common.StripANSI(out)
	common.AssertContains(t, linked, "cmake@"+common.DetectVersion, "detect finds the stub")
	common.AssertContains(t, linked, "fake-cmake", "detect reports the stub's root")

	list := common.ExecOK(t, name, "vfox", "list", "cmake")
	common.AssertContains(t, list, "linked", "list shows the linked version")

	run := common.ExecOK(t, name, "vfox", "exec", "cmake@"+common.DetectVersion, "--", "cmake", "--version")
	common.AssertContains(t, run, "cmake version "+common.DetectVersion, "linked version is usable")
}

// buildStub compiles a CMake-shaped program that prints a fixed version. It
// returns the path of the resulting exe.
func buildStub(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "go.mod"), []byte("module stub\n\ngo 1.24\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	src := "package main\n\nimport \"fmt\"\n\nfunc main() { fmt.Println(\"cmake version " + common.DetectVersion + "\") }\n"
	if err := os.WriteFile(filepath.Join(dir, "main.go"), []byte(src), 0o644); err != nil {
		t.Fatal(err)
	}
	exe := filepath.Join(dir, "cmake.exe")
	cmd := exec.Command("go", "build", "-o", exe, ".")
	cmd.Dir = dir
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("build stub: %v\n--- output ---\n%s", err, out)
	}
	return exe
}
