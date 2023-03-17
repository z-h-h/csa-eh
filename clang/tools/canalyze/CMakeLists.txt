set( LLVM_LINK_COMPONENTS
  ${LLVM_TARGETS_TO_BUILD}
  Option
  Support
  )

add_clang_tool(canalyze++
  canalyze.cpp
  )

clang_target_link_libraries(canalyze++
  PRIVATE
  clangAST
  clangBasic
  clangDriver
  clangFrontend
  clangStaticAnalyzerFrontend
  clangTooling
  clangToolingSyntax
  )
