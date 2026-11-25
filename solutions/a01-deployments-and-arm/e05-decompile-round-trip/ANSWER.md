# a01-e05-decompile-round-trip

## Always lost
Comments. The `// Course original...` line is gone in `fixtures/decompiled.bicep`. Compile drops comments; decompile cannot restore them.

## Often rewritten
Resource symbolic names may change. Parentheses and some interpolations may be rewritten. Decompile is best-effort and prints a warning that JSON which came from Bicep is a less accurate reverse.

## Usually preserved
Variable names that were JSON keys (`suffix`, `fullName`) and the resource type/API version. Parameter names. Output names. String values such as `Standard_LRS`.
