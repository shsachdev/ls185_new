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

  def delete_expenses(id)
    sql = "SELECT * FROM expenses"
    result = @connection.exec(sql)
    if id_exists(result, id)
      delete_result = @connection.exec("SELECT * FROM expenses WHERE id = #{id}")
      puts "The following expense has been deleted:"
      display_expenses(delete_result)
      sql = "DELETE FROM expenses WHERE id = $1"
      @connection.exec_params(sql, [id])
      # delete_message()
    else
      puts "There is no expense with the id #{id}"
    end
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

  def id_exists(expenses, id)
    id_list = []
    expenses.each do |tuple|
      id_list << tuple["id"]
    end
    return false unless id_list.include?(id.to_s)
    true
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
    when "delete"
      id = arguments[0]
      @application.delete_expenses(id)
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
