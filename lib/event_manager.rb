require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'
require 'pry-byebug'
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
    only_digits = phone_number.scan(/[0-9]/)
    phone_number = only_digits.join('')
    if(phone_number[0] == '1' && phone_number.length == 11 )
      return phone_number[1,11]
    elsif   ( (10..11).include?(phone_number.length))
      return phone_number
    else
      return '0000000000'
    end
    
end

def clean_dates(peak_registration_hours)
  split_time = peak_registration_hours.split(' ')
  day_year_month_split = split_time[0].split('/')
  corrected_days = day_year_month_split[2] + '/' + day_year_month_split[0]+ '/' + day_year_month_split[1]
  corrected_date = corrected_days + ' ' + split_time[1]
  t = Time.parse(corrected_date)
end
def find_most_repeated(times)
  hours = times
  i = 0
hour_count = [{'hour' => 'hour_occurences'}]
while hours.length >= 1 do

  current_item = hours[0]
  hour_count.push({hours[0] => hours.count(current_item)})
  hours.filter! {|item| item != current_item}
  i+= 1

end
hour_count
end

def clean_days(days)
  split_time = days.split(' ')
  day_year_month_split = split_time[0].split('/')
  corrected_days = day_year_month_split[2] + '/' + day_year_month_split[0]+ '/' + day_year_month_split[1]
  corrected_date = corrected_days + ' ' + split_time[1]
  Date.parse(corrected_date).cwday
end
def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours = []
days = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])
  hours.push(clean_dates(row[:regdate]).hour)
  days.push(clean_days(row[:regdate]))
  #So for peak registration hours lets break down the steps
  #1. first we need to set up a counter that says how many were in x hour 
  #2 Then we need multiple counter to store the different amounts between hours.
  #2. Then  let's say we have the counters and they have their numbers. then we need to compare them
  #3. We need to select the highest one and display that particular hour counter that says for exple hour 1 - 2 we had 5 signups
  form_letter = erb_template.result(binding)

   save_thank_you_letter(id,form_letter)
   
  
end

def show_most_registered_hours(hours)
counter = find_most_repeated(hours)
sorted_counter = counter[1,counter.length].sort! { |a, b| b.values[0] <=> a.values[0] }
sorted_counter.unshift({ "hours" => "hour amounts"})
end

def show_most_registered_days(days)
  p sorted_days = days.sort! { |a, b| b <=> a}
end

