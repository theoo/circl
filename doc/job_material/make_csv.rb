FILE_1 = "jobs_en.txt"
FILE_2 = "jobs_fr.txt"

result_string = ""

def get_list_of_lines_from_file(file)
  result = []
  File.open(file, "r") { |f| result = f.read.split("\n")  }
  result
end


first_list = get_list_of_lines_from_file(FILE_1)
second_list = get_list_of_lines_from_file(FILE_2)

first_list.zip(second_list) { |a1, a2| result_string << "#{a1}, #{a2}\n" }

puts result_string
