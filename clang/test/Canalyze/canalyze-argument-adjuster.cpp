// RUN: not canalyze "%s" -- -c -v -Werror 2>&1 | FileCheck %s

// CHECK: {{"-analyze"}}

// Argument "-w" is added to cc1 arguments by default if the driver argument "--analyze" is set.
// CHECK: {{"-w"}}

// CHECK-NOT: {{"-Werror"}}

// CHECK: {{"-o" "reports"}}
invalid;
