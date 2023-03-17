// RUN: %clang_analyze_cc1 -analyzer-checker=debug.Stats -verify -Wno-unreachable-code %s

struct S {
  ~S();
};

// the return at the end of an CompoundStmt does not lead to an unreachable block containing the dtors (except the pseudo try block)
void test() { // expected-warning-re{{test -> Total CFGBlocks: {{[0-9]+}} | Unreachable CFGBlocks: 1 | Exhausted Block: no | Empty WorkList: yes}}
  S s;
  return;
}
