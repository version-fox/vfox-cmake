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

package common

import (
	"strings"
	"testing"
)

func TestStripANSI(t *testing.T) {
	got := StripANSI("Install \x1b[92mcmake@3.31.6\x1b[0m success!")
	if want := "Install cmake@3.31.6 success!"; got != want {
		t.Fatalf("StripANSI() = %q, want %q", got, want)
	}
}

func TestContainerName(t *testing.T) {
	a, b := ContainerName("linux"), ContainerName("linux")
	if !strings.HasPrefix(a, ImagePrefix+"-linux-") {
		t.Fatalf("ContainerName() = %q, want prefix %q", a, ImagePrefix+"-linux-")
	}
	if a == b {
		t.Fatalf("ContainerName() returned the same name twice: %q", a)
	}
}
