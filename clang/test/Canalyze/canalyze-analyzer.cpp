// RUN: canalyze "%s" -debug-verify -- -c -v 2>&1 | FileCheck %s

// CHECK: {{"-verify"}}
int f() { return 1 / 0; }
// expected-warning@-1 {{Division by zero [core.DivideZero]}}
