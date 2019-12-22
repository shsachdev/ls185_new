#! /usr/bin/env ruby

require 'pg'


class ExpenseData
  def initialize
    @connection = PG.connect(dbname: "expenses")
  end

  def add_expenses(amount, memo)
    date = Date.today
    sql = "INSERT INTO expenses (amount, memo, created_on) VALUES ($1, $2, $3)"
    @connection.exec_params(sql, [amount, memo, date])
  end

  def search_expenses(memo)
    sql = "SELECT * FROM expenses WHERE memo ILIKE $1"
    result = @connection.exec_params(sql, ["%#{memo}%"])
    display_expenses(result)
  end

  def list_expenses
    result = @connection.exec("SELECT * FROM expenses ORDER BY created_on ASC")
    display_expenses(result)
  end

  private

  def display_expenses(expenses)
    expenses.each do |tuple|
      columns = [tuple["id"].rjust(3), tuple["created_on"].rjust(10),
      tuple["amount"].rjust(12),
      tuple["memo"]]

      puts columns.join(" | ")
    end
  end
end

class CLI
  def initialize
    @application = ExpenseData.new
  end

  def run(arguments)
    command = arguments.shift
    case command
    when "list"
      @application.list_expenses
    when "add"
      amount = arguments[0]
      memo = arguments[1]
      abort "You must provide an amount and memo." unless amount && memo
      @application.add_expenses(amount, memo)
    when "search"
      memo = arguments[0]
      abort "You must provide a memo." unless memo
      @application.search_expenses(memo)
    else
      display_help
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
end

CLI.new.run(ARGV)
