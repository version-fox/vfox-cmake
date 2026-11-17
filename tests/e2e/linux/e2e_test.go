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

// Package linux is the Ubuntu container E2E suite. It builds the image in
// tests/e2e/linux/Dockerfile once and drives setup, install, exec and Detect
// through `docker exec` calls.
package linux

import (
	"path/filepath"
	"strings"
	"testing"

	"github.com/version-fox/vfox-cmake/tests/e2e/common"
)

func TestE2E(t *testing.T) {
	if testing.Short() {
		t.Skip("skip container E2E in short mode")
	}

	image := common.ImagePrefix + ":linux"
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

	name := common.ContainerName("linux")
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

// verifyDetect puts a stub CMake on PATH and checks that vfox link --detect
// finds it, links it, and that the linked version can be executed.
func verifyDetect(t *testing.T, name string) {
	t.Helper()
	stub := "mkdir -p /opt/fake-cmake/bin; " +
		"printf '#!/bin/sh\\necho \"cmake version " + common.DetectVersion + "\"\\n' > /opt/fake-cmake/bin/cmake; " +
		"chmod +x /opt/fake-cmake/bin/cmake"
	common.ExecOK(t, name, "sh", "-c", stub)

	linked := common.ExecOK(t, name,
		"env", "PATH=/opt/fake-cmake/bin:/usr/local/bin:/usr/bin:/bin",
		"vfox", "link", "--detect", "cmake", "--yes")
	common.AssertContains(t, linked, "cmake@"+common.DetectVersion, "detect finds the stub")
	common.AssertContains(t, linked, "/opt/fake-cmake", "detect reports the stub's root")

	list := common.ExecOK(t, name, "vfox", "list", "cmake")
	common.AssertContains(t, list, "linked", "list shows the linked version")

	run := common.ExecOK(t, name, "vfox", "exec", "cmake@"+common.DetectVersion, "--", "cmake", "--version")
	common.AssertContains(t, run, "cmake version "+common.DetectVersion, "linked version is usable")
}
