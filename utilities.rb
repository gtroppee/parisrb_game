class String
  def word_wrap(width=80)
    # Replace newlines with spaces
    gsub(/\n/, ' ').   
    
    # Replace more than one space with a single space
    gsub(/\s+/, ' ').

    # Replace spaces at the beginning of the
    # string with nothing
    gsub(/^\s+/, '').

    # This one is hard to read.  Replace with any amount
    # of space after it with that punctuation and two
    # spaces
    gsub(/([\.\!\?]+)(\s+)?/, '\1  ').

    # Similar to the call above, except replace commas
    # with a comma and one space
    gsub(/\,(\s+)?/, ', ').

    # The meat of the method, replace between 1 and width
    # characters followed by whitespace or the end of the
    # line with that string and a newline.  This works
    # because regular expression engines are greedy,
    # they'll take as many characters as they can.
    gsub(%r[(.{1,#{width}})(?:\s|\z)], "\\1\n")
  end
end