/* SPDX-License-Identifier: BSD-2-Clause */
module iki;
import std::io;

fn int main(String[] args)
{
    @pool() {
        io::print(codegen::tgen("input", `
{{ code }}
int[] arr = { 3, 4, 5 };
{{ end }}

{{ foreach (i, num : arr) }}
    #{ "%d => %d\n", i, num }
{{ end }}
`, C3)!!);
    };
    return 0;
}
