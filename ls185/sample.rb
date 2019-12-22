db = PG.connect(dbname:"films_ls185")

db.exec "SELECT 1"

result = db.exec "SELECT 1"

# The exec method takes a string which is just the SQL method that you wish to execute on the server.

# The exec method on a PG connection object returns a result object. From that result object,
# we are able to gain access to the different results using methods presented in video.

result = db.exec "SELECT * FROM films;"

result.values

result.values.size

result.each do |tuple|
  puts "#{tuple["title"]} came out in #{tuple["year"]}"
end
