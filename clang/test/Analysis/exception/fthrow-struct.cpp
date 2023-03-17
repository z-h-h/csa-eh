// RUN: %clang_analyze_cc1 -fcxx-exceptions -analyzer-checker=debug.ExprInspection -verify %s

void clang_analyzer_dump(int);

struct T {
  const int TAG;

  T(int tag) : TAG(tag) {}
};

void fthrow(int val) { throw T(val); }

void frethrow() { throw; }

int main() {
  try {
    try {
      fthrow(123);
    } catch (const T &a) {
      clang_analyzer_dump(a.TAG); // expected-warning{{123}}
      try {
        try {
          fthrow(456);
        } catch (const T &b) {
          clang_analyzer_dump(b.TAG); // expected-warning{{456}}
          frethrow();
        }
      } catch (const T &c) {
        clang_analyzer_dump(c.TAG); // expected-warning{{456}}
      }
      frethrow();
    }
  } catch (const T &d) {
    clang_analyzer_dump(d.TAG); // expected-warning{{123}}
  }
}
