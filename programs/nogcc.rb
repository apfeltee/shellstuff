#!/usr/bin/ruby

require "ostruct"
require "optparse"

=begin
The following options control optimizations:
  -O<number>                  		
  -Ofast                      		
  -Og                         		
  -Os                         		
  -faggressive-loop-optimizations 	[enabled]
  -falign-functions           		[disabled]
  -falign-functions=          		
  -falign-jumps               		[disabled]
  -falign-jumps=              		
  -falign-labels              		[disabled]
  -falign-labels=             		
  -falign-loops               		[disabled]
  -falign-loops=              		
  -fassociative-math          		[disabled]
  -fassume-phsa               		[enabled]
  -fasynchronous-unwind-tables 		[enabled]
  -fauto-inc-dec              		[enabled]
  -fbranch-count-reg          		[disabled]
  -fbranch-probabilities      		[disabled]
  -fbranch-target-load-optimize 	[disabled]
  -fbranch-target-load-optimize2 	[disabled]
  -fbtr-bb-exclusive          		[disabled]
  -fcaller-saves              		[disabled]
  -fcode-hoisting             		[disabled]
  -fcombine-stack-adjustments 		[disabled]
  -fcompare-elim              		[disabled]
  -fconserve-stack            		[disabled]
  -fcprop-registers           		[disabled]
  -fcrossjumping              		[disabled]
  -fcse-follow-jumps          		[disabled]
  -fcx-fortran-rules          		[disabled]
  -fcx-limited-range          		[disabled]
  -fdce                       		[enabled]
  -fdefer-pop                 		[disabled]
  -fdelayed-branch            		[disabled]
  -fdelete-dead-exceptions    		[disabled]
  -fdelete-null-pointer-checks 		[enabled]
  -fdevirtualize              		[disabled]
  -fdevirtualize-speculatively 		[disabled]
  -fdse                       		[enabled]
  -fearly-inlining            		[enabled]
  -fexceptions                		[disabled]
  -fexpensive-optimizations   		[disabled]
  -ffast-math                 		
  -ffinite-math-only          		[disabled]
  -ffloat-store               		[disabled]
  -fforward-propagate         		[disabled]
  -ffp-contract=[off|on|fast] 		fast
  -ffp-int-builtin-inexact    		[enabled]
  -ffunction-cse              		[enabled]
  -fgcse                      		[disabled]
  -fgcse-after-reload         		[disabled]
  -fgcse-las                  		[disabled]
  -fgcse-lm                   		[enabled]
  -fgcse-sm                   		[disabled]
  -fgraphite                  		[disabled]
  -fgraphite-identity         		[disabled]
  -fguess-branch-probability  		[disabled]
  -fhandle-exceptions         		
  -fhoist-adjacent-loads      		[disabled]
  -fif-conversion             		[disabled]
  -fif-conversion2            		[disabled]
  -findirect-inlining         		[disabled]
  -finline                    		[enabled]
  -finline-atomics            		[enabled]
  -finline-functions          		[disabled]
  -finline-functions-called-once 	[disabled]
  -finline-small-functions    		[disabled]
  -fipa-bit-cp                		[disabled]
  -fipa-cp                    		[disabled]
  -fipa-cp-clone              		[disabled]
  -fipa-icf                   		[disabled]
  -fipa-icf-functions         		[disabled]
  -fipa-icf-variables         		[disabled]
  -fipa-profile               		[disabled]
  -fipa-pta                   		[disabled]
  -fipa-pure-const            		[disabled]
  -fipa-ra                    		[disabled]
  -fipa-reference             		[disabled]
  -fipa-reference-addressable 		[disabled]
  -fipa-sra                   		[disabled]
  -fipa-stack-alignment       		[enabled]
  -fipa-vrp                   		[disabled]
  -fira-algorithm=[CB|priority] 	CB
  -fira-hoist-pressure        		[enabled]
  -fira-loop-pressure         		[disabled]
  -fira-region=[one|all|mixed] 		[default]
  -fira-share-save-slots      		[enabled]
  -fira-share-spill-slots     		[enabled]
  -fisolate-erroneous-paths-attribute 	[disabled]
  -fisolate-erroneous-paths-dereference 	[disabled]
  -fivopts                    		[enabled]
  -fjump-tables               		[enabled]
  -fkeep-gc-roots-live        		[disabled]
  -flifetime-dse              		[enabled]
  -flifetime-dse=<0,2>        		2
  -flimit-function-alignment  		[disabled]
  -flive-patching             		
  -flive-patching=[inline-only-static|inline-clone] 	[default]
  -flive-range-shrinkage      		[disabled]
  -floop-interchange          		[disabled]
  -floop-nest-optimize        		[disabled]
  -floop-parallelize-all      		[disabled]
  -floop-unroll-and-jam       		[disabled]
  -flra-remat                 		[disabled]
  -fmath-errno                		[enabled]
  -fmodulo-sched              		[disabled]
  -fmodulo-sched-allow-regmoves 	[disabled]
  -fmove-loop-invariants      		[disabled]
  -fnon-call-exceptions       		[disabled]
  -fnothrow-opt               		[disabled]
  -fomit-frame-pointer        		[disabled]
  -fopt-info                  		[disabled]
  -foptimize-sibling-calls    		[disabled]
  -foptimize-strlen           		[disabled]
  -fpack-struct               		[disabled]
  -fpack-struct=<number>      		
  -fpartial-inlining          		[disabled]
  -fpatchable-function-entry= 		
  -fpeel-loops                		[disabled]
  -fpeephole                  		[enabled]
  -fpeephole2                 		[disabled]
  -fplt                       		[enabled]
  -fpredictive-commoning      		[disabled]
  -fprefetch-loop-arrays      		[enabled]
  -fprintf-return-value       		[enabled]
  -freciprocal-math           		[disabled]
  -freg-struct-return         		[enabled]
  -frename-registers          		[enabled]
  -freorder-blocks            		[disabled]
  -freorder-blocks-algorithm=[simple|stc] 	simple
  -freorder-blocks-and-partition 	[disabled]
  -freorder-functions         		[disabled]
  -frerun-cse-after-loop      		[disabled]
  -freschedule-modulo-scheduled-loops 	[disabled]
  -frounding-math             		[disabled]
  -frtti                      		[enabled]
  -fsave-optimization-record  		[disabled]
  -fsched-critical-path-heuristic 	[enabled]
  -fsched-dep-count-heuristic 		[enabled]
  -fsched-group-heuristic     		[enabled]
  -fsched-interblock          		[enabled]
  -fsched-last-insn-heuristic 		[enabled]
  -fsched-pressure            		[disabled]
  -fsched-rank-heuristic      		[enabled]
  -fsched-spec                		[enabled]
  -fsched-spec-insn-heuristic 		[enabled]
  -fsched-spec-load           		[disabled]
  -fsched-spec-load-dangerous 		[disabled]
  -fsched-stalled-insns       		[disabled]
  -fsched-stalled-insns-dep   		[enabled]
  -fsched-stalled-insns-dep=<number> 	
  -fsched-stalled-insns=<number> 	
  -fsched2-use-superblocks    		[disabled]
  -fschedule-fusion           		[enabled]
  -fschedule-insns            		[disabled]
  -fschedule-insns2           		[disabled]
  -fsection-anchors           		[disabled]
  -fsel-sched-pipelining      		[disabled]
  -fsel-sched-pipelining-outer-loops 	[disabled]
  -fsel-sched-reschedule-pipelined 	[disabled]
  -fselective-scheduling      		[disabled]
  -fselective-scheduling2     		[disabled]
  -fshort-enums               		[enabled]
  -fshort-wchar               		[disabled]
  -fshrink-wrap               		[disabled]
  -fshrink-wrap-separate      		[enabled]
  -fsignaling-nans            		[disabled]
  -fsigned-zeros              		[enabled]
  -fsimd-cost-model=[unlimited|dynamic|cheap] 	unlimited
  -fsingle-precision-constant 		[disabled]
  -fsplit-ivs-in-unroller     		[enabled]
  -fsplit-loops               		[disabled]
  -fsplit-paths               		[disabled]
  -fsplit-wide-types          		[disabled]
  -fssa-backprop              		[enabled]
  -fssa-phiopt                		[disabled]
  -fstack-check=[no|generic|specific] 	
  -fstack-clash-protection    		[disabled]
  -fstack-protector           		[disabled]
  -fstack-protector-all       		[disabled]
  -fstack-protector-explicit  		[disabled]
  -fstack-protector-strong    		[disabled]
  -fstack-reuse=[all|named_vars|none] 	all
  -fstdarg-opt                		[enabled]
  -fstore-merging             		[disabled]
  -fstrict-aliasing           		[disabled]
  -fstrict-enums              		[disabled]
  -fstrict-volatile-bitfields 		[enabled]
  -fthread-jumps              		[disabled]
  -fno-threadsafe-statics     		[enabled]
  -ftracer                    		[disabled]
  -ftrapping-math             		[enabled]
  -ftrapv                     		[disabled]
  -ftree-bit-ccp              		[disabled]
  -ftree-builtin-call-dce     		[disabled]
  -ftree-ccp                  		[disabled]
  -ftree-ch                   		[disabled]
  -ftree-coalesce-vars        		[disabled]
  -ftree-copy-prop            		[disabled]
  -ftree-cselim               		[enabled]
  -ftree-dce                  		[disabled]
  -ftree-dominator-opts       		[disabled]
  -ftree-dse                  		[disabled]
  -ftree-forwprop             		[enabled]
  -ftree-fre                  		[disabled]
  -ftree-loop-distribute-patterns 	[disabled]
  -ftree-loop-distribution    		[disabled]
  -ftree-loop-if-convert      		[enabled]
  -ftree-loop-im              		[enabled]
  -ftree-loop-ivcanon         		[enabled]
  -ftree-loop-optimize        		[enabled]
  -ftree-loop-vectorize       		[disabled]
  -ftree-lrs                  		[disabled]
  -ftree-parallelize-loops=<number> 	1
  -ftree-partial-pre          		[disabled]
  -ftree-phiprop              		[enabled]
  -ftree-pre                  		[disabled]
  -ftree-pta                  		[disabled]
  -ftree-reassoc              		[enabled]
  -ftree-scev-cprop           		[enabled]
  -ftree-sink                 		[disabled]
  -ftree-slp-vectorize        		[disabled]
  -ftree-slsr                 		[disabled]
  -ftree-sra                  		[disabled]
  -ftree-switch-conversion    		[disabled]
  -ftree-tail-merge           		[disabled]
  -ftree-ter                  		[disabled]
  -ftree-vectorize            		
  -ftree-vrp                  		[disabled]
  -funconstrained-commons     		[disabled]
  -funroll-all-loops          		[disabled]
  -funroll-loops              		[disabled]
  -funsafe-math-optimizations 		[disabled]
  -funswitch-loops            		[disabled]
  -funwind-tables             		[enabled]
  -fvar-tracking              		[enabled]
  -fvar-tracking-assignments  		[enabled]
  -fvar-tracking-assignments-toggle 	[disabled]
  -fvar-tracking-uninit       		[disabled]
  -fvariable-expansion-in-unroller 	[disabled]
  -fvect-cost-model=[unlimited|dynamic|cheap] 	[default]
  -fversion-loops-for-strides 		[disabled]
  -fvpt                       		[disabled]
  -fweb                       		[enabled]
  -fwrapv                     		[disabled]
  -fwrapv-pointer             		[disabled]


=end

#gcc -Q -O0 --help=optimizers 2>&1 #| perl -ane 'if ($F[1] =~/enabled/) {$F[0] =~ s/^\s*-f/-fno-/g;push @o,$F[0];}} END {print join(" ", @o)'

def gather_lines(exe, &b)
  lines = {}
  # list of options that are retardedly implemented, i.e.: "-fira-region" - gcc won't accept "-fno-ira-region"
  shit_opts = [
    
  ]
  rx = /^\s*-\bf(?<name>[\w-]+)\b(=(?<possible>.*))?\s\s*(\[(?<defstatus>\w+)\])/
  IO.popen([exe, "-Q", "-O0", "--help=optimizers"], "rb") do |io|
    io.each_line do |line|
      line.strip!
      line.scrub!
      next if (line[0] != '-')
      m = line.match(rx)
      if not m then
        $stderr.printf("failed to match %p\n", line)
      else
        name = m["name"].strip
        possib = m["possible"]
        status = m["defstatus"].strip.downcase
        nocmd = "-fno-#{name}"
        if name.match?(/^no-/) || (possib != nil) then
          $stderr.printf("skipping ambigious option %p\n", "-f#{name}")
          next
        end
        if (status == "enabled") || (status == "default") then
          $stderr.printf("adding %p\n", nocmd)
          b.call(nocmd)
        end
      end
    end
  end
end

=begin
gcc: error: unrecognized command line option ‘-fno-fshort-enums’; did you mean ‘-fno-short-enums’?
                                              -fno-short-enums
=end

def make_final_command(opts, args)
  exe = (if opts.iscpp then "g++" else "gcc" end)
  cmd = [exe, "-O0"]
  opts.includes.each do |v|
    cmd.push("-I#{v}")
  end
  opts.linkdirs.each do |v|
    cmd.push("-L#{v}")
  end
  gather_lines(exe) do |o|
    cmd.push(o)
  end
  args.each do |a|
    cmd.push(a)
  end
  opts.linklibs.each do |v|
    cmd.push("-l#{v}")
  end
  if opts.outname then
    cmd.push("-o", opts.outname)
  end
  $stderr.printf("final cmd: %p\n", cmd)
  exec(*cmd)
end

begin
  opts = OpenStruct.new({
    iscpp: false,
    includes: [],
    linklibs: [],
    linkdirs: [],
  })

  optparse = OptionParser.new do |prs|
    prs.on("-h[<etc>]", "--help"){
      puts("this script just calls gcc. use 'gcc --help' instead.")
      puts("here are the options this script will try to process (which are forwarded to gcc):")
      puts(prs.help)
      exit(1)
    }
    prs.on("-o<v>"){|v|
      opts.outname = v 
    }
    prs.on("-I<v>"){|v|
      opts.includes.push(v)
    }
    prs.on("-L<v>"){|v|
      opts.linkdirs.push(v)
    }
    prs.on("-l<v>"){|v|
      opts.linklibs.push(v)
    }
  end

  arguments = ARGV.dup
  secondary = []
  first_run = true
  errors = false
  while errors || first_run
    errors = false
    first_run = false
    begin
      optparse.order!(arguments) do |unrecognized_option|
        secondary.push(unrecognized_option)
      end
    rescue OptionParser::InvalidOption => e
      errors = true
      e.args.each { |arg| secondary.push(arg) }
      arguments.delete(e.args)
    end
  end

  primary = ARGV.dup
  secondary.each do |cuke_arg|
    primary.delete(cuke_arg)
  end

=begin
primary:   ["-lm", "-o", "cock.exe"]
secondary: ["mandel.c", "-S"]
arguments: []
#<OpenStruct includes=[], linklibs=["m"], linkdirs=[], outname="cock.exe">
=end


  rt = optparse.parse(primary)

=begin
  printf("primary:   %p\n", primary)
  printf("secondary: %p\n", secondary)
  printf("arguments: %p\n", arguments)
  printf("rt:        %p\n", rt)
  p opts
=end
  secondary.each do |a|
    a = a.scrub
    if a.match?(/\.C$/) || a.match?(/\.(cc|cpp|cxx|c\+\+)$/i) then
      opts.iscpp = true
      break
    end
  end
  make_final_command(opts, secondary)
end







