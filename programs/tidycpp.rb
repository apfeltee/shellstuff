#!/usr/bin/ruby

require "ostruct"
require "optparse"

class OptionParser
  # Like order!, but leave any unrecognized --switches alone
  def order_recognized!(args)
    extra_opts = []
    begin
      order!(args) { |a| extra_opts << a }
    rescue OptionParser::InvalidOption => e
      extra_opts << e.args[0]
      retry
    end
    args[0, 0] = extra_opts
  end
end

=begin

Enabled checks:
    clang-analyzer-apiModeling.StdCLibraryFunctions
    clang-analyzer-apiModeling.TrustNonnull
    clang-analyzer-apiModeling.google.GTest
    clang-analyzer-apiModeling.llvm.CastValue
    clang-analyzer-apiModeling.llvm.ReturnValue
    clang-analyzer-core.CallAndMessage
    clang-analyzer-core.CallAndMessageModeling
    clang-analyzer-core.DivideZero
    clang-analyzer-core.DynamicTypePropagation
    clang-analyzer-core.NonNullParamChecker
    clang-analyzer-core.NonnilStringConstants
    clang-analyzer-core.NullDereference
    clang-analyzer-core.StackAddrEscapeBase
    clang-analyzer-core.StackAddressEscape
    clang-analyzer-core.UndefinedBinaryOperatorResult
    clang-analyzer-core.VLASize
    clang-analyzer-core.builtin.BuiltinFunctions
    clang-analyzer-core.builtin.NoReturnFunctions
    clang-analyzer-core.uninitialized.ArraySubscript
    clang-analyzer-core.uninitialized.Assign
    clang-analyzer-core.uninitialized.Branch
    clang-analyzer-core.uninitialized.CapturedBlockVariable
    clang-analyzer-core.uninitialized.UndefReturn
    clang-analyzer-cplusplus.InnerPointer
    clang-analyzer-cplusplus.Move
    clang-analyzer-cplusplus.NewDelete
    clang-analyzer-cplusplus.NewDeleteLeaks
    clang-analyzer-cplusplus.PlacementNew
    clang-analyzer-cplusplus.PureVirtualCall
    clang-analyzer-cplusplus.SelfAssignment
    clang-analyzer-cplusplus.SmartPtrModeling
    clang-analyzer-cplusplus.VirtualCallModeling
    clang-analyzer-deadcode.DeadStores
    clang-analyzer-fuchsia.HandleChecker
    clang-analyzer-nullability.NullPassedToNonnull
    clang-analyzer-nullability.NullReturnedFromNonnull
    clang-analyzer-nullability.NullabilityBase
    clang-analyzer-nullability.NullableDereferenced
    clang-analyzer-nullability.NullablePassedToNonnull
    clang-analyzer-nullability.NullableReturnedFromNonnull
    clang-analyzer-optin.cplusplus.UninitializedObject
    clang-analyzer-optin.cplusplus.VirtualCall
    clang-analyzer-optin.mpi.MPI-Checker
    clang-analyzer-optin.osx.OSObjectCStyleCast
    clang-analyzer-optin.osx.cocoa.localizability.EmptyLocalizationContextChecker
    clang-analyzer-optin.osx.cocoa.localizability.NonLocalizedStringChecker
    clang-analyzer-optin.performance.GCDAntipattern
    clang-analyzer-optin.performance.Padding
    clang-analyzer-optin.portability.UnixAPI
    clang-analyzer-osx.API
    clang-analyzer-osx.MIG
    clang-analyzer-osx.NSOrCFErrorDerefChecker
    clang-analyzer-osx.NumberObjectConversion
    clang-analyzer-osx.OSObjectRetainCount
    clang-analyzer-osx.ObjCProperty
    clang-analyzer-osx.SecKeychainAPI
    clang-analyzer-osx.cocoa.AtSync
    clang-analyzer-osx.cocoa.AutoreleaseWrite
    clang-analyzer-osx.cocoa.ClassRelease
    clang-analyzer-osx.cocoa.Dealloc
    clang-analyzer-osx.cocoa.IncompatibleMethodTypes
    clang-analyzer-osx.cocoa.Loops
    clang-analyzer-osx.cocoa.MissingSuperCall
    clang-analyzer-osx.cocoa.NSAutoreleasePool
    clang-analyzer-osx.cocoa.NSError
    clang-analyzer-osx.cocoa.NilArg
    clang-analyzer-osx.cocoa.NonNilReturnValue
    clang-analyzer-osx.cocoa.ObjCGenerics
    clang-analyzer-osx.cocoa.RetainCount
    clang-analyzer-osx.cocoa.RetainCountBase
    clang-analyzer-osx.cocoa.RunLoopAutoreleaseLeak
    clang-analyzer-osx.cocoa.SelfInit
    clang-analyzer-osx.cocoa.SuperDealloc
    clang-analyzer-osx.cocoa.UnusedIvars
    clang-analyzer-osx.cocoa.VariadicMethodTypes
    clang-analyzer-osx.coreFoundation.CFError
    clang-analyzer-osx.coreFoundation.CFNumber
    clang-analyzer-osx.coreFoundation.CFRetainRelease
    clang-analyzer-osx.coreFoundation.containers.OutOfBounds
    clang-analyzer-osx.coreFoundation.containers.PointerSizedValues
    clang-analyzer-security.FloatLoopCounter
    clang-analyzer-security.insecureAPI.DeprecatedOrUnsafeBufferHandling
    clang-analyzer-security.insecureAPI.SecuritySyntaxChecker
    clang-analyzer-security.insecureAPI.UncheckedReturn
    clang-analyzer-security.insecureAPI.bcmp
    clang-analyzer-security.insecureAPI.bcopy
    clang-analyzer-security.insecureAPI.bzero
    clang-analyzer-security.insecureAPI.decodeValueOfObjCType
    clang-analyzer-security.insecureAPI.getpw
    clang-analyzer-security.insecureAPI.gets
    clang-analyzer-security.insecureAPI.mkstemp
    clang-analyzer-security.insecureAPI.mktemp
    clang-analyzer-security.insecureAPI.rand
    clang-analyzer-security.insecureAPI.strcpy
    clang-analyzer-security.insecureAPI.vfork
    clang-analyzer-unix.API
    clang-analyzer-unix.DynamicMemoryModeling
    clang-analyzer-unix.Malloc
    clang-analyzer-unix.MallocSizeof
    clang-analyzer-unix.MismatchedDeallocator
    clang-analyzer-unix.Vfork
    clang-analyzer-unix.cstring.BadSizeArg
    clang-analyzer-unix.cstring.CStringModeling
    clang-analyzer-unix.cstring.NullArg
    clang-analyzer-valist.CopyToSelf
    clang-analyzer-valist.Uninitialized
    clang-analyzer-valist.Unterminated
    clang-analyzer-valist.ValistBase
    clang-analyzer-webkit.NoUncountedMemberChecker
    clang-analyzer-webkit.RefCntblBaseVirtualDtor



=end



CHECKS = <<__eol__

    performance-faster-string-find
    performance-for-range-copy
    performance-implicit-conversion-in-loop
    performance-inefficient-algorithm
    performance-inefficient-string-concatenation
    performance-inefficient-vector-operation
    performance-move-const-arg
    performance-move-constructor-init
    performance-noexcept-move-constructor
    performance-type-promotion-in-math-fn
    performance-unnecessary-copy-initialization
    performance-unnecessary-value-param

    portability-simd-intrinsics


    misc-definitions-in-headers
    misc-misplaced-const
    misc-new-delete-overloads
    misc-non-copyable-objects
    misc-non-private-member-variables-in-classes
    misc-redundant-expression
    misc-static-assert
    misc-throw-by-value-catch-by-reference
    misc-unconventional-assign-operator
    misc-uniqueptr-reset-release
    misc-unused-alias-decls
    misc-unused-using-decls
    misc-unused-parameters:Strict

    bugprone-argument-comment
    bugprone-assert-side-effect
    bugprone-bad-signal-to-kill-thread
    bugprone-bool-pointer-implicit-conversion
    bugprone-branch-clone
    bugprone-copy-constructor-init
    bugprone-dangling-handle
    bugprone-dynamic-static-initializers
    bugprone-exception-escape
    bugprone-fold-init-type
    bugprone-forward-declaration-namespace
    bugprone-forwarding-reference-overload
    bugprone-inaccurate-erase
    bugprone-incorrect-roundings
    bugprone-infinite-loop
    bugprone-integer-division
    bugprone-lambda-function-name
    bugprone-macro-repeated-side-effects
    bugprone-misplaced-operator-in-strlen-in-alloc
    bugprone-misplaced-pointer-arithmetic-in-alloc
    bugprone-misplaced-widening-cast
    bugprone-move-forwarding-reference
    bugprone-multiple-statement-macro
    bugprone-narrowing-conversions
    bugprone-no-escape
    bugprone-not-null-terminated-result
    bugprone-parent-virtual-call
    bugprone-posix-return
    bugprone-redundant-branch-condition
    bugprone-signal-handler
    bugprone-signed-char-misuse
    bugprone-sizeof-container
    bugprone-sizeof-expression
    bugprone-spuriously-wake-up-functions
    bugprone-string-constructor
    bugprone-string-integer-assignment
    bugprone-string-literal-with-embedded-nul
    bugprone-suspicious-enum-usage
    bugprone-suspicious-include
    bugprone-suspicious-memset-usage
    bugprone-suspicious-string-compare
    bugprone-swapped-arguments
    bugprone-terminating-continue
    bugprone-throw-keyword-missing
    bugprone-too-small-loop-variable
    bugprone-undefined-memory-manipulation
    bugprone-undelegated-constructor
    bugprone-unhandled-self-assignment
    bugprone-unused-raii
    bugprone-unused-return-value
    bugprone-use-after-move
    bugprone-virtual-near-miss

    readability-isolate-declaration
    readability-braces-around-statements
    readability-const-return-type
    readability-container-size-empty
    readability-delete-null-pointer
    readability-deleted-default
    readability-function-size

    readability-implicit-bool-conversion
    readability-inconsistent-declaration-parameter-name

    readability-magic-numbers
    readability-misleading-indentation
    readability-misplaced-array-index

    readability-non-const-parameter
    readability-redundant-control-flow
    readability-redundant-declaration
    readability-redundant-function-ptr-dereference
    readability-redundant-member-init
    readability-redundant-preprocessor
    readability-redundant-smartptr-get
    readability-redundant-string-cstr
    readability-redundant-string-init
    readability-simplify-boolean-expr
    readability-simplify-subscript-expr
    readability-static-accessed-through-instance

    readability-string-compare
    readability-uniqueptr-delete-release
__eol__


def vexec(*cmd)
  $stderr.printf("cmd: %s\n", cmd.map{| s|  s.dump[1 .. -2] }.join(" "))

  exec(*cmd)
end

def getchecks
  rt = []
  CHECKS.each_line do |ln|
    ln.strip!
    next if ln.empty?
    next if ln.match?(/^\s*#/)
    rt.push(ln)
  end
  return rt
end

def clangtidy(files, opts)
  iscpp = false
  files.each{|f|
    if f.match?(/\.(cpp|cc|cxx|c\+\+)$/i) then
      iscpp = true
    end
  }
  cmd = ["clang-tidy"]
  cmd.push("-w") if opts.nowarnings
  cmd.push("-quiet") if opts.quiet
  cmd.push("--extra-arg=-std=c++20") if iscpp
  if not opts.includes.empty? then
    opts.includes.each do |inc|
      cmd.push(sprintf("-extra-arg-before=-I%s", inc))
    end
  end
  opts.extra.each do |ex|
    cmd.push(sprintf("-extra-arg-before=%s", ex))
  end
  cmd.push(*files)
  if opts.force then
    cmd.push("-fix-errors")
  end
  cmd.push("-fix")
  cmd.push(sprintf("-checks=%s", getchecks.join(",")))
  vexec(*cmd)
end

begin
  opts = OpenStruct.new({
    force: false,
    quiet: false,
    nowarnings: false,
    includes: [],
    extra: [],
  })
  oprs = OptionParser.new{|prs|  
    prs.on("-h", "--help"){
      system("clang-tidy", "--help")
      puts("---[ options for 'tidycpp' ]---")
      puts(prs.help)
      exit(0)
    }
    prs.on("-I<s>", "--include=<s>"){|v|
      opts.includes.push(v)
    }
    prs.on("-x<s>", "--extra=<s>"){|v|
      opts.extra.push(v)
    }
    prs.on("-f", "--force", "uses '-fix-errors', causing clang-tidy to continue despite errors (dangerous!)"){
      opts.force = true
    }
    prs.on("-q", "--quiet"){
      opts.quiet = true
    }
    prs.on("-w", "suppress warnings"){
      opts.nowarnings = true
    }
  }
  nargv = oprs.order_recognized!(ARGV)
  p ARGV
  clangtidy(ARGV, opts)
end

