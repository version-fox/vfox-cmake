# escape=`
# Copyright 2026 Han Li and contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Windows target for the E2E suite. No CMake here on purpose: CMake may only
# come from what vfox installs, apart from the stub used for Detect.
ARG BASE_IMAGE=mcr.microsoft.com/windows/servercore:ltsc2025-amd64
FROM ${BASE_IMAGE}

SHELL ["powershell", "-NoProfile", "-Command"]
ENV VFOX_HOME=C:\vfox-home

ARG VFOX_VERSION=1.1.0
ARG VFOX_SHA256=1bbec8fffddbb62de0d93030c3f6203c69680662bc65257ca4a5e611cb607d0a

RUN $ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/version-fox/vfox/releases/download/v${VFOX_VERSION}/vfox_${VFOX_VERSION}_windows_x86_64.zip" -OutFile C:\vfox.zip; if ((Get-FileHash -Algorithm SHA256 C:\vfox.zip).Hash.ToLower() -ne "${VFOX_SHA256}") { throw 'vfox checksum mismatch' }; Expand-Archive -Force -Path C:\vfox.zip -DestinationPath C:\vfox; $exe = Get-ChildItem -Path C:\vfox -Filter vfox.exe -Recurse | Select-Object -First 1; Copy-Item -Path $exe.FullName -Destination C:\Windows\System32\vfox.exe; Remove-Item -Force C:\vfox.zip; Remove-Item -Recurse -Force C:\vfox

RUN New-Item -ItemType Directory -Force -Path C:\vfox-home\plugin\cmake | Out-Null
COPY metadata.lua C:/vfox-home/plugin/cmake/metadata.lua
COPY hooks C:/vfox-home/plugin/cmake/hooks
COPY lib C:/vfox-home/plugin/cmake/lib

# Long-lived container: the Go test drives every phase through exec calls.
ENTRYPOINT ["C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe", "-NoProfile", "-Command"]
CMD ["while ($true) { Start-Sleep 3600 }"]
