// Copyright 2017-2018 Stratumn SAS. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Package main contains Stratumn's Indigo Command-line interface.
// The CLI helps create Indigo applications and networks.
//
// Unless otherwise noted, the source files are distributed under the Apache
// License 2.0 found in the LICENSE file.
//
// Third party dependencies included in the vendor directory are distributed
// under their respective licenses.
package main

import "github.com/stratumn/indigo-cli/cmd"

const (
	version = "x.x.x"
	commit  = "00000000000000000000000000000000"
)

func main() {
	cmd.Execute(version, commit)
}
