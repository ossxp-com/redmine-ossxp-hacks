#!/usr/bin/ruby

#Set path to your en_GB english file 
file_eng = 'en.yml';

# Set true if you would like to have original file with 'bck' extension 
do_backup_file = FALSE;

if (ARGV.size < 1)
	puts "Usage: #tl_lang_parser.php <localization_file_to_be_updated>"
	exit
else
	file_lang_old = ARGV[0];
end

out=''; # data for output file
var_counter = 0;
var_counter_new = 0;
var_counter_untrans = 0;
var_counter_trans = 0;

puts "===== Start TestLink lang_parser =====";

# read en.yml
if File.exist?(file_eng) && File.readable?(file_eng)
	puts"English file #{file_eng} is readable OK."
	lines_eng = File.new(file_eng).readlines.size 
	lines_eng_content = File.new(file_eng).readlines 
else
	puts "English file #{file_eng} is readable - FAILED!. Exit."
end
# read language file
if (File.exist?(file_lang_old) && File.readable?(file_lang_old))
	puts "File #{file_lang_old} is readable OK."
	lines_lang_old = File.new(file_lang_old).readlines.size
	lines_lang_old_content = File.new(file_lang_old).readlines
else
	puts " #{file_lang_old} file is not readable - FAILED!. Exit."
end

puts "English file lines =#{lines_eng}"
puts "Old Language file lines =#{lines_lang_old}"

# find end of english header	:\s(\d+)\s
for i in 0...lines_eng
    if(/_gloc_rule_default.*/=~ lines_eng_content[i])
        begin_line = i+1
        puts "Eng: End of header is line = #{i} " 
        break
    end
end

# copy existing localization file header
for i in 0...lines_lang_old
    if /_gloc_rule_default.*/m =~ lines_lang_old_content[i]
        puts "Old: End of header is line = #{i} "
        begin_line_old = i + 1	    
		out+=Regexp.last_match(0).to_s
        out+="* ------------------------------------------- */\n"
        break
    end
end

# compile output array based on english file
i = begin_line-1
while true
    i += 1
    break if i >= lines_eng

    # copy empty line
    if /^\s*$/=~lines_eng_content[i]
        puts "(line #{i}) Empty line"
        out+= "\n"

    # parse a line with variable definition
    elsif /([\w]+)\s*:\s*(.*)/.match(lines_eng_content[i]) 
        var_name = Regexp.last_match[1].to_s
        var_counter+=1
        bLocalized = FALSE
        localizedLine = ''
        
        # get localized value if defined - parse old localized strings
		for k in begin_line_old...lines_lang_old
        	if /^#{var_name}\s*:(.*)$/m =~ lines_lang_old_content[k]
		        puts "Found localized variable on (line #{k}) >>> #{lines_lang_old_content[k]}"
				bLocalized = TRUE
		        localizedLine = Regexp.last_match.to_s
			
				# check if localized value exceed to more lines - semicolon is not found
=begin
		while ( !(  /;\s*$/ =~ lines_lang_old_content[k] ||
                            /;\s*[\/]{2}[^'"]*$/ =~ lines_lang_old_content[k] ) )
                    k+=1
			        puts "Multiline localized value (line #{k})"
		            localizedLine += lines_lang_old_content[k]
		        end
=end 
                break
		end	
       end 
        
        orig_eng = lines_eng_content[i]
        
        puts "(line #{i}) Found variable '$#{var_name}'"
        if bLocalized
	        puts "Localization exists #{localizedLine}"
            puts 
            if localizedLine.strip == orig_eng.strip
                var_counter_untrans=var_counter_untrans+1
            else
                var_counter_trans=var_counter_trans+1
            end
            out+= "#{localizedLine}"
	  
	else 
	        puts "Localization doesn't exists. Copy English."
                var_counter_untrans+=1
		var_counter_new+=1
		out+="#{orig_eng}"
        end
	# end of file    
    elsif /^\?\>/.match(lines_eng_content[i])
        out+= "?>\n";

	# something wrong?
    else
    	puts "ERROR: please fix the unparsed line #{i}: #{lines_eng_content[i]}"
  end
# create backup if defined
    if (do_backup_file)
    	rename(file_lang_old, "#{file_lang_old}.bck");
    end
# save output
fp = open(file_lang_old, "w")
fp.puts out
fp.close

end
puts "Updated file: #{file_lang_old}";
puts "Completed! The script has parsed #{var_counter} strings and add #{var_counter_new} new variables.";
puts "Un-translate items: #{var_counter_untrans} , translated items: #{var_counter_trans}";
puts "===== Bye =====";
