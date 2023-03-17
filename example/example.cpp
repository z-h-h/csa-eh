
void clang_analyzer_dump(int);

void example() {
    try {
        try {
            throw 1;
        } catch (...) {
            throw 2;
        }
    } catch (...) {
        try {
            throw 3;
        } catch (...) {
            throw 4;
        }
    }
}

int main() {
    try {
        example();
    } catch (int e) {
        clang_analyzer_dump(e);
    }
}