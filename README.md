# SQLiteDataSwift
Simple Sqlite3 wrapper for Swift 4, because sometimes you just want to write queries and get the results without any hassle.

SQLiteDataQuery provides an easy-to-use DataTable class for query results.

## Features
- Easy to use and understand Swift interface.
- No need to manage OpaquePointer statements, SQLiteDataQuery manages query statements for you.
- Extend SQLiteConnector to create classes with interfaces specific to the data they manage.
- Well-documented methods.
- DataTable class for easily cycling through results from a SELECT query.

## In The Works
- Support for Blobs.
- Mapping of query results to a custom Class so that results can be an Array of custom objects.
- Better/Cleaner test cases to make development easier.

## Usage
```swift

//setup a database connection by passing name of database file to open or create
//database file is created in the user's document directory
var database = SQLiteConnector(databaseName: "database_file_name")

//to use the database connection, open it
try! database.open()

//run your queries

//get the last generated row id from an INSERT statement
let accountID = database.lastRowId()

//get the total number of rows changed ( on UPDATE or DELETE )
let totalChangedRows = database.totalChanges()

//remove parameters and finalize the statement
database.clear()

//close the connection
database.close()

```

### Using the execute(String) and execute() methods for INSERT, UPDATE, DELETE, CREATE

```swift

//use to create a table
try! database.execute("create table account(account_id integer primary key, name text, description text)")

//use to insert data
try! database.execute("insert into account(name, description) values('john', 'marketing and sales')")
try! database.execute("insert into account(name, description) values('lisa', 'development')")

//use parameters
database.setParameter(name: "accountName", value: "Lex")
database.setParameter(name: "accountDesc", value: "Print Designer")

try! database.execute("insert into account(name, description) values(@accountName, @accountDesc)")

//change the parameters for a new entry
database.setParameter(name: "accountName", value: "Todd")
database.setParameter(name: "accountDesc", value: "Graphic Designer")

//use execute() to re-execute the last statement( this method doesn't re-compile the statement )
try! database.execute()

//clear the parameters ( this needs to be done before executing a statement with different parameters )
database.clearParameters()


```
### Using the executeScalar(String) and executeScalar methods for SELECT statements that return a single value

```swift

database.setParameter(name: "accountName", value: "john")
let johnAccountID = try! database.executeScalar("select account_id from account where name=@accountName") as! Int

//use executeScalar() so the statement isn't re-compiled
database.setParameter(name: "accountName", value: "lisa")
let lisaAccountID = try! database.executeScalar() as! Int

database.clearParameters()

let totalAccounts = try! database.executeScalar("select count(*) from account") as! Int


```

### Using the executeDataTable(String) and executeDataTable() methods for SELECT statements that return data sets
```swift

//returns a datatable where each row has an element for each column in the select list
let table = try! database.executeDataTable("select * from account")

//access individual rows and their column data
let firstName = table.rows[0]["name"] as! String

//loop through all the rows
for row in table.rows {
  print(row["name"] as! String)
  print(row["description"] as! String)
}


```



## Contact
- [Gail Sparks](mailto:gailsparks@gmail.com)

