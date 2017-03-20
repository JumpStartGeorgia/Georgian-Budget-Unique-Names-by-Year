# read in each xlsx file and create a new spreadsheet that combines all years into one sheet so can compare if text is same

require 'rubyXL'
require 'csv'

start = Time.now
folder_path = '../Georgian-Budget-Files/files_from_government/monthly_spreadsheets'

if !File.exist? folder_path
  puts "The monthly budget files do not exist at #{folder_path}"
  return
end

# get the years from the folder names
years = Dir.glob(folder_path + "/*").map{|x| x.split('/').last}.sort

if years.nil? || years.length == 0
  puts "The year folders of the monthly budget files could not be found"
  return
end

items = []
item_template = {code: nil, type: nil, data_tyep: nil}
years.each do |year|
  item_template[year] = nil
end

puts "> this is the template: #{item_template}"


years.each do |year|
  puts "-> working on year #{year}"
  files = Dir.glob("#{folder_path}/#{year}/*.xlsx")
puts "--> #{files.length} files were found to parse"


  # go through each file and record the programs / spending agencies
  files.each do |file|
    month_data = RubyXL::Parser.parse(file)
    puts "- worksheets = #{month_data.count}"
    puts "- rows = #{month_data[0].count}"

    month_data[0][6..month_data[0].count].each_with_index do |row, index|
      # puts "index #{index+7}"
      # puts ">> #{row[0].value} ||| #{row[1].value}"
      # if the first col is left aligned and the 3rd column is blank, this is a new item
      if !row[0].nil? && !row[0].value.nil? && row[0].horizontal_alignment == 'left' && (row[2].nil? || row[2].value.nil? || row[2].value.to_s.strip == '')# || row[2].value.strip == ''
        # create/find new item
        item = items.select{|x| x[:code] == row[0].value.to_s.strip}.first

        if item.nil?
          item = item_template.dup
          item[:code] = row[0].value.to_s.strip
          item[:code] = '00' if row[0].value == '0' || row[0].value == 0

          item[:data_type] = row[0].value.class.to_s
          # puts "> code = '#{item[:code]}'; type = #{item[:data_type]}"

          if item[:data_type] == 'DateTime'
            # this should be a series of 3 2-digit numbers as a string that is automatically being converted to a date
            # in format: 2037-01-07T00:00:00+00:00
            # - split by T to get date and then pull out the pieces we need
            date = item[:code].value.to_s.split('T').first

            item[:code] = "#{date[2..3]} #{date[5..6]} #{date[8..9]}"
          end

          # set the type by looking at the code
          # - length = 5 and ends in 00, spending agency
          # - length = 5 and not end in 00, program
          # - length = 8, sub-program
          # - length = 11, sub-sub-program
          # - length = 14, sub-sub-sub-program
          item[:type] = if item[:code].length() == 5
            if item[:code].split(//).last(2).join == '00'
              'spending agency'
            else
              'program'
            end
          elsif item[:code].length() == 8
            'sub-program'
          elsif item[:code].length() == 11
            'sub-sub-program'
          elsif item[:code].length() == 14
            'sub-sub-sub-program'
          end

          # make sure if this is 00 that it does not already exist
          # have to do this because we may have to manually set value to 00 after first select search above
          if (item[:code] == '00' && items.select{|x| x[:code] == '00'}.length > 0)
            item = items.select{|x| x[:code] == '00'}.first
          else
            items << item
          end
        end

        # add the text for this year
        item[year] = row[1].value.to_s.strip
      end
    end
  end

end


puts "========"
puts "there are #{items.length} items recorded"

# puts items.select{|x| x[:code] == '24 01 01'}.map{|x| {code: x[:code], type: x[:type], data_type: x[:data_type]}}

# create csv output in format of:
# code, type, year (name)
CSV.open("names_by_year.csv", 'wb') do |csv|
  header = %w{code type}
  years.each do |year|
    header << year
  end
  header << 'same text over time?'
  csv << header

  items.sort_by{|x| x[:code]}.each do |item|
    row = [item[:code], item[:type]]

    # if year exists, add it, else nil
    years.each do |year|
      if item[year].nil?
        row << nil
      else
        row << item[year]
      end
    end

    # compare text for all years and see if same
    matches = row[2..row.length].select{|x| !x.nil?}
    # puts "- code = #{item[:code]}; matches = #{matches.length}; uniq = #{matches.uniq.length}"
    row << (matches.uniq.length == 1)

    csv << row
  end
end

puts "========"
puts "it took #{Time.now-start} seconds to process files"