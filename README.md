# Georgian Budget - Unique Names by Year
Get a unique list of programs/agencies by year and spit it out to a CSV file. 

This script uses the monthly spreadsheets from the [Georgian Budget File repo](https://github.com/JumpStartGeorgia/Georgian-Budget-Files). The script assumes that the Georgian Budget File repo is in a folder at the same level as this repo and the folder name is Georgian-Budget-Files.

To run the script:
* Pull the latest version of the Georgian Budget File repo
* From the console type `ruby process_files.rb`
* A file called `names_by_year.csv` will be generated

The CSV file has the following columns:
* code - the code of the agency/program
* type - indicates whether the item is an agency, program, or sub-program
* years - each of the next set of columns represents a year; the header indicates which year
* same text over time? - this is a flag that indicates whether or not the names for each year have the same text

The CSV file is used in the [Georgian Budget - Priority Mapping repo](https://github.com/JumpStartGeorgia/Georgian-Budget-Priority-Mapping).
