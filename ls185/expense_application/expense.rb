#! /usr/bin/env ruby

require 'pg'


def list_expenses
  connection = PG.connect(dbname: "expenses")

  result = connection.exec("SELECT * FROM expenses ORDER BY created_on ASC")
  result.each do |tuple|
    columns = [tuple["id"].rjust(3), tuple["created_on"].rjust(10),
    tuple["amount"].rjust(12),
    tuple["memo"]]

    puts columns.join(" | ")
  end
end


def display_help
  puts "An Expense recording system"

  puts "Commands:"

  puts "add AMOUNT MEMO [DATE] - record a new expense"
  puts "clear - delete all expenses"
  puts "list - list all expenses"
  puts "delete NUMBER - remove expenses with id number"
  puts "search QUERY - list expenses with a matching memo field"
end

command = ARGV.first

if command == "list"
  list_expenses
else
  display_help
end
