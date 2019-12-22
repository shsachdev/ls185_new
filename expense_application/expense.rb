#! /usr/bin/env ruby

require 'pg'

CONNECTION = PG.connect(dbname: "expenses")

# code structure needs to be changed

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
  puts <<~HELP
    An expense recording system

    Commands:

    add AMOUNT MEMO [DATE] - record a new expense
    clear - delete all expenses
    list - list all expenses
    delete NUMBER - remove expense with id NUMBER
    search QUERY - list expenses with a matching memo field
  HELP
end

# adding a change

def add_expenses(amount, memo)
  date = Date.today
  sql = "INSERT INTO expenses (amount, memo, created_on) VALUES ($1, $2, $3)"
  CONNECTION.exec_params(sql, [amount, memo, date])
end

command = ARGV.first

case command
when "list"
  list_expenses
when "add"
  amount = ARGV[1]
  memo = ARGV[2]
  abort "You must provide an amount and memo." unless amount && memo
  add_expenses(amount, memo)
when nil
  display_help
end
