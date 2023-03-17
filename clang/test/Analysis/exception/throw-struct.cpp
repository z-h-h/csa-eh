// RUN: %clang_analyze_cc1 -fcxx-exceptions -analyzer-checker=debug.ExprInspection -verify %s

void clang_analyzer_dump(int);

struct T {
  const int TAG;

  T(int tag) : TAG(tag) {}
};

int main() {
  try {
    try {
      throw T(123);
    } catch (const T &a) {
      clang_analyzer_dump(a.TAG); // expected-warning{{123}}
      try {
        try {
          throw T(456);
        } catch (const T &b) {
          clang_analyzer_dump(b.TAG); // expected-warning{{456}}
          throw;
        }
      } catch (const T &c) {
        clang_analyzer_dump(c.TAG); // expected-warning{{456}}
      }
      throw;
    }
  } catch (const T &d) {
    clang_analyzer_dump(d.TAG); // expected-warning{{123}}
  }
}
