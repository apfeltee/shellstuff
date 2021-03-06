#!/usr/bin/ruby

require "shellwords"

WINPYTHON = "c:/scripting/python3/python.exe"
EMSCRIPTENPATH ="C:/cloud/local/code/programs/emsdk/upstream/emscripten/"

DEFAULT_OPTS = {
  "WASM" => 0,
}

VALID_EMSETTINGS = %w(
  ASSERTIONS
  RUNTIME_LOGGING
  STACK_OVERFLOW_CHECK
  VERBOSE
  INVOKE_RUN
  EXIT_RUNTIME
  MEM_INIT_METHOD
  TOTAL_STACK
  MALLOC
  ABORTING_MALLOC
  FAST_UNROLLED_MEMCPY_AND_MEMSET
  INITIAL_MEMORY
  MAXIMUM_MEMORY
  ALLOW_MEMORY_GROWTH
  MEMORY_GROWTH_GEOMETRIC_STEP
  MEMORY_GROWTH_GEOMETRIC_CAP
  MEMORY_GROWTH_LINEAR_STEP
  ALLOW_TABLE_GROWTH
  GLOBAL_BASE
  DOUBLE_MODE
  WARN_UNALIGNED
  PRECISE_F32
  SIMD
  USE_CLOSURE_COMPILER
  CLOSURE_WARNINGS
  DECLARE_ASM_MODULE_EXPORTS
  IGNORE_CLOSURE_COMPILER_ERRORS
  INLINING_LIMIT
  AGGRESSIVE_VARIABLE_ELIMINATION
  SIMPLIFY_IFS
  SAFE_HEAP
  SAFE_HEAP_LOG
  RESERVED_FUNCTION_POINTERS
  ALIASING_FUNCTION_POINTERS
  EMULATED_FUNCTION_POINTERS
  EMULATE_FUNCTION_POINTER_CASTS
  EXCEPTION_DEBUG
  DEMANGLE_SUPPORT
  LIBRARY_DEBUG
  SYSCALL_DEBUG
  SOCKET_DEBUG
  SOCKET_WEBRTC
  WEBSOCKET_URL
  PROXY_POSIX_SOCKETS
  WEBSOCKET_SUBPROTOCOL
  OPENAL_DEBUG
  WEBSOCKET_DEBUG
  GL_ASSERTIONS
  TRACE_WEBGL_CALLS
  GL_DEBUG
  GL_TESTING
  GL_MAX_TEMP_BUFFER_SIZE
  GL_UNSAFE_OPTS
  FULL_ES2
  GL_EMULATE_GLES_VERSION_STRING_FORMAT
  GL_EXTENSIONS_IN_PREFIXED_FORMAT
  GL_SUPPORT_AUTOMATIC_ENABLE_EXTENSIONS
  GL_TRACK_ERRORS
  GL_SUPPORT_EXPLICIT_SWAP_CONTROL
  GL_POOL_TEMP_BUFFERS
  WORKAROUND_OLD_WEBGL_UNIFORM_UPLOAD_IGNORED_OFFSET_BUG
  USE_WEBGL2
  MIN_WEBGL_VERSION
  MAX_WEBGL_VERSION
  WEBGL2_BACKWARDS_COMPATIBILITY_EMULATION
  FULL_ES3
  LEGACY_GL_EMULATION
  GL_FFP_ONLY
  GL_PREINITIALIZED_CONTEXT
  USE_WEBGPU
  STB_IMAGE
  WORKAROUND_IOS_9_RIGHT_SHIFT_BUG
  GL_DISABLE_HALF_FLOAT_EXTENSION_IF_BROKEN
  JS_MATH
  POLYFILL_OLD_MATH_FUNCTIONS
  LEGACY_VM_SUPPORT
  ENVIRONMENT
  LZ4
  DISABLE_EXCEPTION_CATCHING
  EXCEPTION_CATCHING_WHITELIST
  NODEJS_CATCH_EXIT
  NODEJS_CATCH_REJECTION
  ASYNCIFY
  ASYNCIFY_IMPORTS
  ASYNCIFY_IGNORE_INDIRECT
  ASYNCIFY_STACK_SIZE
  ASYNCIFY_BLACKLIST
  ASYNCIFY_WHITELIST
  ASYNCIFY_LAZY_LOAD_CODE
  ASYNCIFY_DEBUG
  EXPORTED_RUNTIME_METHODS
  EXTRA_EXPORTED_RUNTIME_METHODS
  CASE_INSENSITIVE_FS
  FILESYSTEM
  FORCE_FILESYSTEM
  NODERAWFS
  NODE_CODE_CACHING
  EXPORTED_FUNCTIONS
  EXPORT_ALL
  EXPORT_BINDINGS
  EXPORT_FUNCTION_TABLES
  RETAIN_COMPILER_SETTINGS
  DEFAULT_LIBRARY_FUNCS_TO_INCLUDE
  LIBRARY_DEPS_TO_AUTOEXPORT
  INCLUDE_FULL_LIBRARY
  SHELL_FILE
  RELOCATABLE
  MAIN_MODULE
  SIDE_MODULE
  RUNTIME_LINKED_LIBS
  BUILD_AS_WORKER
  PROXY_TO_WORKER
  PROXY_TO_WORKER_FILENAME
  PROXY_TO_PTHREAD
  LINKABLE
  STRICT
  IGNORE_MISSING_MAIN
  AUTO_ARCHIVE_INDEXES
  STRICT_JS
  WARN_ON_UNDEFINED_SYMBOLS
  ERROR_ON_UNDEFINED_SYMBOLS
  SMALL_XHR_CHUNKS
  HEADLESS
  DETERMINISTIC
  MODULARIZE
  MODULARIZE_INSTANCE
  SEPARATE_ASM_MODULE_NAME
  EXPORT_ES6
  USE_ES6_IMPORT_META
  BENCHMARK
  ASM_JS
  FINALIZE_ASM_JS
  SWAPPABLE_ASM_MODULE
  SEPARATE_ASM
  DEAD_FUNCTIONS
  EXPORT_NAME
  DYNAMIC_EXECUTION
  EMTERPRETIFY
  EMTERPRETIFY_FILE
  EMTERPRETIFY_BLACKLIST
  EMTERPRETIFY_WHITELIST
  EMTERPRETIFY_ASYNC
  EMTERPRETIFY_ADVISE
  EMTERPRETIFY_SYNCLIST
  RUNNING_JS_OPTS
  BOOTSTRAPPING_STRUCT_INFO
  STRUCT_INFO
  EMSCRIPTEN_TRACING
  USE_GLFW
  WASM
  STANDALONE_WASM
  WASM_BACKEND
  BINARYEN_SCRIPTS
  BINARYEN_IGNORE_IMPLICIT_TRAPS
  BINARYEN_TRAP_MODE
  BINARYEN_PASSES
  BINARYEN_EXTRA_PASSES
  WASM_ASYNC_COMPILATION
  WASM_BIGINT
  EMIT_PRODUCERS_SECTION
  EMIT_EMSCRIPTEN_METADATA
  EMIT_EMSCRIPTEN_LICENSE
  LEGALIZE_JS_FFI
  USE_SDL
  USE_SDL_GFX
  USE_SDL_IMAGE
  USE_SDL_TTF
  USE_SDL_NET
  USE_ICU
  USE_ZLIB
  USE_BZIP2
  USE_LIBJPEG
  USE_LIBPNG
  USE_REGAL
  USE_BOOST_HEADERS
  USE_BULLET
  USE_VORBIS
  USE_OGG
  USE_FREETYPE
  USE_SDL_MIXER
  USE_HARFBUZZ
  USE_COCOS2D
  SDL2_IMAGE_FORMATS
  IN_TEST_HARNESS
  USE_PTHREADS
  PTHREAD_POOL_SIZE
  PTHREAD_POOL_DELAY_LOAD
  DEFAULT_PTHREAD_STACK_SIZE
  PTHREADS_PROFILING
  ALLOW_BLOCKING_ON_MAIN_THREAD
  PTHREADS_DEBUG
  MEMORYPROFILER
  ELIMINATE_DUPLICATE_FUNCTIONS
  ELIMINATE_DUPLICATE_FUNCTIONS_DUMP_EQUIVALENT_FUNCTIONS
  ELIMINATE_DUPLICATE_FUNCTIONS_PASSES
  EVAL_CTORS
  CYBERDWARF
  BUNDLED_CD_DEBUG_FILE
  TEXTDECODER
  EMBIND_STD_STRING_IS_UTF8
  OFFSCREENCANVAS_SUPPORT
  OFFSCREENCANVASES_TO_PTHREAD
  OFFSCREEN_FRAMEBUFFER
  FETCH_SUPPORT_INDEXEDDB
  FETCH_DEBUG
  FETCH
  USE_FETCH_WORKER
  ASMFS
  SINGLE_FILE
  AUTO_JS_LIBRARIES
  MIN_FIREFOX_VERSION
  MIN_SAFARI_VERSION
  MIN_IE_VERSION
  MIN_EDGE_VERSION
  MIN_CHROME_VERSION
  SUPPORT_ERRNO
  MINIMAL_RUNTIME
  MINIMAL_RUNTIME_STREAMING_WASM_COMPILATION
  MINIMAL_RUNTIME_STREAMING_WASM_INSTANTIATION
  USES_DYNAMIC_ALLOC
  SUPPORT_LONGJMP
  DISABLE_DEPRECATED_FIND_EVENT_TARGET_BEHAVIOR
  HTML5_SUPPORT_DEFERRING_USER_SENSITIVE_REQUESTS
  MINIFY_HTML
  MAYBE_WASM2JS
  ASAN_SHADOW_SIZE
  DISABLE_EXCEPTION_THROWING
  USE_OFFSET_CONVERTER
  LLD_REPORT_UNDEFINED
  DEFAULT_TO_CXX
  OFFSCREEN_FRAMEBUFFER_FORBID_VAO_PATH
  TEST_MEMORY_GROWTH_FAILS
)

def get_configfile(n)
  vars = {}
  rt = []
  return rt unless %w(emcc em++).include?(n)
  cfg = File.join(ENV["HOME"], ".emscripten")
  if File.file?(cfg) then
    File.foreach(cfg) do |line|
      line.strip!
      next if line.empty?
      next if line[0] == '#'
      next unless line.include?("=")
      rest = line.split("=")
      word = rest.shift.strip
      next unless VALID_EMSETTINGS.include?(word)
      reststr = rest.join("=").strip
      begin
        data = eval(reststr)
        $stderr.printf("config: %s -> %p\n", word, data)
        vars[word] = data
      rescue => ex
        $stderr.printf("config: failed to eval %p: (%s) %s\n", reststr, ex.class.name, ex.message)
      end
    end
  end
  DEFAULT_OPTS.each do |k, v|
    if not vars.key?(k) then
      vars[k] = v
    end
  end
  vars.each do |k, v|
    rt.push("-s", sprintf("%s=%p", k, v))
  end
  return rt
end

def check
  if not File.directory?(EMSCRIPTENPATH) then
    $stderr.printf("emscripten path %p does not exist!\n", EMSCRIPTENPATH)
    exit(1)
  end
  if (not File.file?(WINPYTHON)) || (not File.executable?(WINPYTHON)) then
    $stderr.printf("windows python executable %p is missing, or not executable!\n")
    exit(1)
  end
end

def cleanpath
  removeme = [
    File.join(ENV["HOME"], "bin"),
    "/cygdrive/c/cloud/local/dev/clangfix/bin",
  ]
  pushme = [
    "/cygdrive/c/progra~1/llvm/bin",
  ]
  stats = []
  removeme.each do |ritm|
    if (st = (File.stat(ritm) rescue nil)) != nil then
      stats.push(st)
    end
  end
  if not stats.empty? then
    npath = [*pushme]
    ENV["PATH"].split(":").each do |itm|
      itm.strip!
      next if itm.empty?
      if (st = (File.stat(itm) rescue nil)) != nil then
        if not stats.include?(st) then
          npath.push(itm)
        else
          $stderr.printf("cleanpath: filtering out %p\n", itm)
        end
      end
    end
    ENV["PATH"] = npath.join(":")
  end
end

def listcommands
  myname = File.basename($0)
  $stderr.printf("other available commands:\n")
  Dir.glob(EMSCRIPTENPATH+'/*.py') do |file|
    name = File.basename(file).gsub(/\.py$/, "")
    $stderr.printf("  %s %s\n", myname, name)
  end
end

begin
  myname = File.basename($0)
  check
  $stderr.printf("argv: %p\n", ARGV)
  wantedprog = ARGV.shift
  if (wantedprog == nil) || %w(help -h -help --help).include?(wantedprog) then
    $stderr.printf("this script is a wrapper for the windows installation of emscripten.\n")
    $stderr.printf("try using '%s emcc' - or any of these:\n", myname)
    listcommands
    exit(1)
  else
    empath = File.join(EMSCRIPTENPATH, (wantedprog + ".py"))
    if not File.file?(empath) then
      $stderr.printf("cannot find command %p (would be %p)!\n", wantedprog, empath)
      $stderr.printf("try '%s --help' to get a list of commands.\n", myname)
      exit(1)
    else
      dv = get_configfile(wantedprog)
      cmd = [WINPYTHON, empath, *dv, *ARGV]
      cleanpath()
      p ENV["PATH"].split(":")
      $stderr.printf("cmd: %s\n", cmd.join(" "))
      exec(*cmd)
    end
  end
end