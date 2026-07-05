#!/bin/bash


# eman 在容器內執行範例在 /workspace/examples 底下
EXAMPLES_DIR="$(dirname "$0")/examples"
C_DIR="${EXAMPLES_DIR}/c"
VERILATOR_DIR="${EXAMPLES_DIR}/verilator"




c_compiler_version() {
    echo "===== C Compiler Version ====="
    gcc --version | head -1
    make --version | head -1
}


c_compiler_example() {
    echo "===== Compile & Run C Example ====="
    cd "${C_DIR}" || return 1
    make
    make clean
}


check_verilator() {
    echo "===== Verilator Version ====="
    verilator --version
    make --version | head -1
}

#Verilator 範例
verilator_example() {
    echo "===== Compile & Run Verilator Example ====="
    cd "${VERILATOR_DIR}" || return 1
    make
    make run
    make clean
}

# 主邏輯
case "${1:-}" in
    c-compiler-version)
        c_compiler_version
        ;;
    c-compiler-example)
        c_compiler_example
        ;;
    check-verilator)
        check_verilator
        ;;
    verilator-example)
        verilator_example
        ;;
    help|"")
        echo "Usage: eman {c-compiler-version|c-compiler-example|check-verilator|verilator-example}"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run 'eman help' for usage."
        ;;
esac