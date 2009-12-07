#!/usr/bin/ruby

require 'getoptlong'

DEFAULT_REFERENCE="en.yml"
$opt_verbose = FALSE

def verbose(msg)
  $stderr.puts msg if $opt_verbose
end

def translate(ref, trans, out)
  if out == trans
    do_backup_file = TRUE;
  else
    do_backup_file = FALSE;
  end

  if not File.readable?(ref)
    $stderr.puts "Reference file #{ref} not found or not readable."
    exit 1
  elsif not File.readable? trans
    $stderr.puts "Translate file #{trans} not found or not readable."
    exit 1
  elsif out and not File.writable? out
    $stderr.puts "Output file #{out} not writable."
    exit 1
  end

  buffers=[]; # data for output file
  counter_total = 0;
  counter_new = 0;
  counter_untrans = 0;
  counter_trans = 0;

  verbose "===== Start lang_parser =====";

  # read ref file
  ref_lines = File.new(ref).readlines

  # read language file
  trans_lines = File.new(trans).readlines

  verbose "Reference file lines =#{ref_lines.size}"
  verbose "Translate file lines =#{trans_lines.size}"

  # find end of reference file header  :\s(\d+)\s
  ref_header_size = 0
  for line in ref_lines
    if line =~ /(^[_#])|(^\s*$)/
      ref_header_size += 1
    else
      verbose "Ref: End of header is line = #{ref_header_size} "
      break
    end
  end

  trans_header_size = 0
  # copy existing localization file header
  for line in trans_lines
    if line =~ /(^[_#])|(^\s*$)/
      buffers << line.rstrip
      trans_header_size += 1
    else
      verbose "Trans: End of header is line = #{trans_header_size} "
      break
    end
  end

  # compile output array based on english file
  i = ref_header_size-1
  while true
    i += 1
    break if i >= ref_lines.size

    # copy empty line
    if ref_lines[i] =~ /^\s*$/
      verbose "(line #{i}) Empty line"
      buffers << ""

    # parse a line with variable definition
    elsif /^([\w]+)\s*:\s*(.*)/.match(ref_lines[i])
      key = $1
      counter_total+=1
      bLocalized = FALSE
      localizedLine = ''
      ref_origin = ref_lines[i].rstrip

      verbose "(line #{i}) Found variable '$#{key}'"

      # get localized value if defined - parse old localized strings
      for k in trans_header_size...trans_lines.size
        if trans_lines[k] =~ /^#{key}\s*:(.*)$/
          verbose "Found localized variable on (line #{k}) >>> #{trans_lines[k]}"
          bLocalized = TRUE
          localizedLine = $&
          break
        end
      end

      if bLocalized
        verbose "Localization exists #{localizedLine}"
        if localizedLine.strip == ref_origin.strip
            counter_untrans += 1
        else
            counter_trans += 1
        end
        buffers << localizedLine
      else
        verbose "Localization doesn't exists. Copy from reference."
        counter_untrans +=1
        counter_new += 1
        buffers << ref_origin
      end
    end
  end

  # create backup if defined
  if do_backup_file
    rename(trans, "#{trans}.bak");
  end

  # save output
  if out
    verbose "Updated file: #{out}"
    fp = open(out, "w")
    fp.puts buffers.join("\n")
    fp.close
  else
    $stdout.puts buffers.join("\n")
  end

  verbose "Completed! The script has parsed #{counter_total} strings and add #{counter_new} new variables."
  verbose "Un-translate items: #{counter_untrans} , translated items: #{counter_trans}"
  verbose "===== Bye ====="
end

def usage
  puts <<END
Command:
  #{$0} [options...] <translate_file>
Usage:
  --reference, -r  <reference_file>
      Default is en.yml

  --output, -o <output_file>
      Default is stdout

  --verbose
      Show verbose message on stderr

  --help
      This screen

  <translate_file>
      Target l10n file.
END
end

def main
  ref = DEFAULT_REFERENCE
  out = nil
  trans = nil
  opts = GetoptLong.new(
    [ "--reference","--source","-s","-r", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--output",   "-o",                 GetoptLong::REQUIRED_ARGUMENT ],
    [ "--verbose",  "-v",                 GetoptLong::NO_ARGUMENT ],
    [ "--help",     "-h",                 GetoptLong::NO_ARGUMENT ]
  )
  # process the parsed options
  opts.each do |opt, arg|
    case opt
    when "--reference"
      ref = arg
    when "--output"
      out = arg
    when "--verbose"
      $opt_verbose = TRUE
    when "--help"
      usage
      exit 0
    end
  end

  if ARGV.size != 1
    usage "Only one arguments, but #{ARGV.size} provided."
    exit 1
  else
    trans = ARGV[0]
  end
  translate ref, trans, out
end

main

exit 1


