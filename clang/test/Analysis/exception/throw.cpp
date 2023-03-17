// RUN: %clang_analyze_cc1 -fcxx-exceptions -analyzer-checker=debug.ExprInspection -verify %s

void clang_analyzer_dump(int);

int main() {
  try {
    try {
      throw 123;
    } catch (int a) {
      clang_analyzer_dump(a); // expected-warning{{123}}
      try {
        try {
          throw 456;
        } catch (int b) {
          clang_analyzer_dump(b); // expected-warning{{456}}
          throw;
        }
      } catch (int c) {
        clang_analyzer_dump(c); // expected-warning{{456}}
      }
      throw;
    }
  } catch (int d) {
    clang_analyzer_dump(d); // expected-warning{{123}}
  }
}
