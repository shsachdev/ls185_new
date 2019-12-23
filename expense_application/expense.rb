#! /usr/bin/env ruby

require 'pg'


class ExpenseData
  def initialize
    @connection = PG.connect(dbname: "expenses")
    setup_schema
  end

  def setup_schema
    sql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'expenses';"
    result = @connection.exec(sql)
    if result.values[0][0].to_i == 0
      create_table_sql = "CREATE TABLE expenses (
        id serial PRIMARY KEY,
        amount numeric(6,2) NOT NULL,
        memo text NOT NULL,
        created_on date NOT NULL
      );

      ALTER TABLE expenses ADD CONSTRAINT positive_amount CHECK (amount >= 0.01);"

      @connection.exec(create_table_sql)
    end
  end

  def add_expenses(amount, memo)
    date = Date.today
    sql = "INSERT INTO expenses (amount, memo, created_on) VALUES ($1, $2, $3)"
    @connection.exec_params(sql, [amount, memo, date])
  end

  def search_expenses(memo)
    sql = "SELECT * FROM expenses WHERE memo ILIKE $1"
    result = @connection.exec_params(sql, ["%#{memo}%"])
    display_and_total_expenses(result)
  end

  def list_expenses
    result = @connection.exec("SELECT * FROM expenses ORDER BY created_on ASC")
    if result.values.size == 0
      puts "There are no expenses."
    else
      display_and_total_expenses(result)
    end
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

  def clear_expenses
    puts "This will remove all expenses. Are you sure? (y/n)"
    answer = gets.chomp
    if answer == "y"
      @connection.exec("DELETE FROM expenses")
      puts "All expenses have been deleted."
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

  def display_and_total_expenses(expenses)
    display_expenses(expenses)
    total_values = []
    expenses.each do |tuple|
      total_values << tuple["amount"].to_i
    end
    puts "--------------------------------------------------"
    puts "Total: #{total_values.sum}"
  end

  def id_exists(expenses, id) # check if input id number actually exists or not 
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
    when "clear"
      @application.clear_expenses
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
