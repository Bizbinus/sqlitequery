//
//  SQLiteConnector.swift
//  SQLiteQuery
//
//  Created by Gail Sparks on 12/17/17.
//  Copyright © 2017 Bizbin LLC. All rights reserved.
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import SQLite3

/// A list of errors that a SQLiteConnector throws
public enum SQLiteConnectorError: Error
{
	case databaseCouldNotBeOpenedOrCreated(reason: String)
	case databaseAlreadyOpen
	case statementCouldNotBeCompiled(reason: String)
	case parameterCouldNotBeBound(reason: String)
	case executionError(reason: String)
	case resultSetNotScalar
	case attemptingToExecuteQueryOnClosedDatabase
	case attemptingToExecuteEmptyQuery
	
}

/// A wrapper class for the sqlite3 api. This class encapsulates and manages a single compiled statement.
open class SQLiteConnector {
	
	private var db: OpaquePointer?
	private var statement: OpaquePointer?
	private var dbFileUrl: URL?
	private var opened = false
	private var statementParameters = [String: Any]()
	private var prevRawQuery = ""
	
	public var fileUrl: String? {
		if dbFileUrl != nil {
			return dbFileUrl!.absoluteString
		} else {
			return nil
		}
	}
	
	/**
		Initialize a SQLiteConnector with an existing database or the name of the database to create
	
	- Parameter databaseName: Name of the database to open or create

	*/
	
	public init(databaseName: String) {
		
		let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		
		dbFileUrl = docDir.appendingPathComponent(databaseName)
		
		
	}
	
/**
	Determines if the SQLite database has been opened or not
*/
	public func isOpen() -> Bool {
		return opened
	}
	
	/**
		Closes the SQLite database if it has been opened. Calling close on a closed database doesn't do anything.
	*/
	public func close() {
		
		if (isOpen()) {
			sqlite3_close(db)
			opened = false
		}
		
	}
	
	/**
		Opens the named database or creates it if it doesn't exist.
	
	- Throws: `SQLiteConnectorError.databaseAlreadyOpen` if the database is already opened. `SQLiteConnectorError.databaseCouldNotBeOpenedOrCreated(reason: reason)` if the database could not be created or opened.
	
	*/
	public func open() throws {
		
		if isOpen() {
			throw SQLiteConnectorError.databaseAlreadyOpen
		}
	
		if sqlite3_open(dbFileUrl!.absoluteString, &db) != SQLITE_OK {
			let reason = String(cString: sqlite3_errmsg(db))
			throw SQLiteConnectorError.databaseCouldNotBeOpenedOrCreated(reason: reason)
		}
		
		opened = true
		
	}
	
	/**
		Retreives the last sqlite3 rowid that is auto generated( unless WITHOUT_ROWID was used ) for the most recent successful INSERT into a rowid table.
	
	- Returns: the most recent rowid recorded. This is 0 if no INSERT was done previously.
	*/
	public func lastRowId() -> Int {
		return Int(sqlite3_last_insert_rowid(db))
	}
	
	/**
		Gets the total number of rows inserted, updated, or deleted from the last modifying query.
	
	- Returns: total rows changed from most recent INSERT, UPDATE, or DELETE
	*/
	public func totalChanges() -> Int {
		let changes = Int(sqlite3_changes(statement))
		return changes
	}
	
	/**
		Determines if a table exists or not

	- Parameter tableName: name of table to check if exists in this database
	
- Returns: true if table exists, false otherwise

	*/
	public func tableExists(_ tableName: String) -> Bool {
	
		setParameter(name: "tableName", value: tableName)
	
		let count = try! executeScalar("select count(*) from sqlite_master where type='table' and name=@tableName") as! Int
	
		clearParameters()
	
		return count > 0
	
	
	}
	
	// MARK: - SQL Interface
	
	/**
		Executes the last query that was compiled without having to provide the same query string.  Use this method on subsequent query executions where only the parameters change.
	
	- Throws: `SQLiteConnectorError.attemptingToExecuteQueryOnClosedDatabase` if database is not open.
	`SQLiteConnectorError.attemptingToExecuteEmptyQuery` if no query string was provided.
	'SQLiteConnectorError.statementCouldNotBeCompiled(reason: reason)` if statement couldn't be compiled.
	`SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)` if any variable couldn't be bound to the compiled statement.
	`SQLiteConnectorError.executionError(reason: reason)` if there was a problem executing the query.
	
	*/
	public func execute() throws {
		
		try execute(prevRawQuery)
		
	}
	
	/**
	Compiles, binds any variables, and executes queryString
	
	- Parameter queryString: the SQL statement to compile and execute
	
	- Throws: `SQLiteConnectorError.attemptingToExecuteQueryOnClosedDatabase` if database is not open.
	`SQLiteConnectorError.attemptingToExecuteEmptyQuery` if no query string was provided.
	`SQLiteConnectorError.statementCouldNotBeCompiled(reason: reason)` if statement couldn't be compiled.
	`SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)` if any variable couldn't be bound to the compiled statement.
	`SQLiteConnectorError.executionError(reason: reason)` if there was a problem executing the query.
	
	*/
	public func execute(_ queryString: String) throws {
		
		if !isOpen() {
			throw SQLiteConnectorError.attemptingToExecuteQueryOnClosedDatabase
		}
		
		if queryString == "" {
			throw SQLiteConnectorError.attemptingToExecuteEmptyQuery
		}
	
		try prepare(queryString)

		try prepareVariables()

		
		
		let result = sqlite3_step(statement)
		
		if result != SQLITE_DONE && result != SQLITE_ROW {
			let reason = String(cString: sqlite3_errmsg(db))
			throw SQLiteConnectorError.executionError(reason: reason)
		}
		
	}

	/**
	Executes the last query that was compiled without having to provide the same query string. Use this method on subsequent query executions where only the parameters change.
	
	- Throws: `SQLiteConnectorError.attemptingToExecuteQueryOnClosedDatabase` if database is not open.
	`SQLiteConnectorError.attemptingToExecuteEmptyQuery` if no query string was provided.
	`SQLiteConnectorError.statementCouldNotBeCompiled(reason: reason)` if statement couldn't be compiled.
	`SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)` if any variable couldn't be bound to the compiled statement.
	`SQLiteConnectorError.resultSetNotScalar` if the query returns more than 1 column
	`SQLiteConnectorError.executionError(reason: reason)` if there was a problem executing the query.
	
	- Returns: A value of type Any? which can be nil, Int, String, or Double.
	*/
	public func executeScalar() throws -> Any? {
		return try executeScalar(prevRawQuery)
	}
	
	/**
	Compiles, binds any variables, and executes queryString with a single result. Returns error if query has more than 1 column in the result set.
	
	- Parameter queryString: the SQL statement to compile and execute.
	
	- Throws: `SQLiteConnectorError.attemptingToExecuteQueryOnClosedDatabase` if database is not open.
	`SQLiteConnectorError.attemptingToExecuteEmptyQuery` if no query string was provided.
	`SQLiteConnectorError.statementCouldNotBeCompiled(reason: reason)` if statement couldn't be compiled.
	`SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)` if any variable couldn't be bound to the compiled statement.
	`SQLiteConnectorError.resultSetNotScalar` if the query returns more than 1 column
	`SQLiteConnectorError.executionError(reason: reason)` if there was a problem executing the query.
	
	- Returns: A value of type Any? which can be nil, Int, String, or Double.
	*/
	public func executeScalar(_ queryString: String) throws -> Any? {
		
		if !isOpen() {
			throw SQLiteConnectorError.attemptingToExecuteQueryOnClosedDatabase
		}
		
		if queryString == "" {
			throw SQLiteConnectorError.attemptingToExecuteEmptyQuery
		}
		
		try prepare(queryString)
		
		try prepareVariables()

		
		let result = sqlite3_step(statement)
		
		let numColumns = sqlite3_data_count(statement)
		
		if numColumns > 1 {
			throw SQLiteConnectorError.resultSetNotScalar
		}
		
		
		
		if result != SQLITE_DONE && result != SQLITE_ROW {
			let reason = String(cString: sqlite3_errmsg(db))
			throw SQLiteConnectorError.executionError(reason: reason)
			
			
		}
		
		//the result could be DONE or ROW
		if numColumns == 1 {
			return columnValue(0)
		}
	
		//if no results then return nil
		return nil
		
	}
	
	/**
	Executes the last query that was compiled without having to provide the same query string. Use this method on subsequent query executions where only the parameters change.
	
	- Throws: `SQLiteConnectorError.attemptingToExecuteQueryOnClosedDatabase` if database is not open.
	`SQLiteConnectorError.attemptingToExecuteEmptyQuery` if no query string was provided.
	`SQLiteConnectorError.statementCouldNotBeCompiled(reason: reason)` if statement couldn't be compiled.
	`SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)` if any variable couldn't be bound to the compiled statement.
	`SQLiteConnectorError.executionError(reason: reason)` if there was a problem executing the query.
	`DataTableError.columnNameAlreadyExists(columnName: columnName)` if a column is added to the DataTable more than once.
	
	- Returns: A DataTable with rows from the resulting query. Access values using DataTable.rows[rowIndex][columnName]. Values are of type Any? and can be nil, Int, Double, String
	*/
	public func executeDataTable() throws -> DataTable {
		
		return try executeDataTable(prevRawQuery)
	}
	
	/**
	Compiles, binds any variables, and executes queryString and puts the results in a DataTable.
	
	- Parameter queryString: the SELECT SQL statement to compile and execute.
	
	- Throws: `SQLiteConnectorError.attemptingToExecuteQueryOnClosedDatabase` if database is not open.
	`SQLiteConnectorError.attemptingToExecuteEmptyQuery` if no query string was provided.
	`SQLiteConnectorError.statementCouldNotBeCompiled(reason: reason)` if statement couldn't be compiled.
	`SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)` if any variable couldn't be bound to the compiled statement.
	`SQLiteConnectorError.executionError(reason: reason)` if there was a problem executing the query.
	`DataTableError.columnNameAlreadyExists(columnName: columnName)` if a column is added to the DataTable more than once.
	
	- Returns: A DataTable with rows from the resulting query. Access values using DataTable.rows[rowIndex][columnName]. Values are of type Any? and can be nil, Int, Double, String
	*/
	public func executeDataTable(_ queryString: String) throws -> DataTable {
		
		if !isOpen() {
			throw SQLiteConnectorError.attemptingToExecuteQueryOnClosedDatabase
		}
		
		if queryString == "" {
			throw SQLiteConnectorError.attemptingToExecuteEmptyQuery
		}
		
		let table = DataTable()
		
		try prepare(queryString)
		
		try prepareVariables()
		
		let totalColumns = sqlite3_column_count(statement)
		
		for index in 0...(totalColumns-1) {
			
			let name = String(cString: sqlite3_column_name(statement, index))
			
			try table.appendColumn(name)
			
		}
		
		//add the rows
		
		while(sqlite3_step(statement) == SQLITE_ROW) {
			
			let r = table.newRow()
			
			for index in 0...(totalColumns-1) {
				r[Int(index)] = columnValue(Int(index))
				
			}
			
			table.appendRow(r)
			
		}
		
		return table
		
	}

	// MARK: - Statement Parameters
	/**
	Set a parameter and value to be bound to the statement before execution. Setting parameter name again overwrites existing value. Clear a parameter name by setting it to nil.
	
	- Parameter name: name of parameter ( don't include sqlite variable prefix )
	- Parameter value: any value of type Int, Double, or String. If value is nil, removes the parameter name.
	
	*/
	public func setParameter(name: String, value: Any)  {
		
		statementParameters[name] = value
		
		
	}
	
	/**
	Clears any bound parameters from the statement and clears all parameters that have been stored for execution.
	
	*/
	public func clearParameters() {
		
		clearStatementParameters()
		
		statementParameters = [String: Any]()
		
	}
	
	// MARK: - Reset and Cleanup
	/**
	Resets a compiled statement so it can be executed again
	
	*/
	public func resetStatement() {
		if statement != nil {
			sqlite3_reset(statement)
		}
	}
	
	/**
	Cleans the currently compiled statement by calling `sqlite3_finalize`. Does not clear the stored parameters.
	
	*/
	public func finalize() {
		
		if statement != nil {
			sqlite3_finalize(statement)
			
		}
		
		statement = nil
		prevRawQuery = ""
	}
	
	/**
	Clears all parameters and finalizes the statement
	
	*/
	public func clear() {
		
		clearParameters()
		finalize()
	}
	
	// MARK: - Private
	/**
	Gets the value of the cell at column `columnIndex` on a compiled statement
	
	- Parameter columnIndex: The index of the column to retreive the value from at this current `step` of the compiled statement.

	- Returns: Value that is of type nil, Int, Double, or String
	
	*/
	private func columnValue(_ columnIndex: Int) -> Any? {
		
		let type = sqlite3_column_type(statement, Int32(columnIndex))
		
		if type == SQLITE_INTEGER {
			return Int(sqlite3_column_int(statement, Int32(columnIndex)))
		} else if type == SQLITE_FLOAT {
			return Double(sqlite3_column_double(statement, Int32(columnIndex)))
		} else if type == SQLITE_TEXT {
			return String(cString: sqlite3_column_text(statement, Int32(columnIndex)))
		} else {
			return nil
		}
		
	}
	/**
	Binds any variables stored in statementVariables to the variable names in the SQL query statement. Any existing statement parameters are unbound first.
	
	- Throws: `SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)` if error occured binding variable to statement. Reason gives error message from database pointer.

	*/
	private func prepareVariables() throws {
		
		clearStatementParameters()
		
		//for each statementParam, apply the variable
		for (key, value) in statementParameters {
			
			
			let pindex = sqlite3_bind_parameter_index(statement, String(format: "@%@", key))
			
			if pindex == 0 {
				let reason = String(cString: sqlite3_errmsg(db))
				throw SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)
			}

			//for now only supporting int, text, and double
			
			if value is Int {
				if sqlite3_bind_int64(statement, pindex, sqlite3_int64(value as! Int)) != SQLITE_OK {
					let reason = String(cString: sqlite3_errmsg(db))
					throw SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)
				}
			} else if value is Int32 {
				if sqlite3_bind_int(statement, pindex, value as! Int32) != SQLITE_OK {
					let reason = String(cString: sqlite3_errmsg(db))
					throw SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)
				}
			} else if value is Int64 {
				if sqlite3_bind_int64(statement, pindex, sqlite3_int64(value as! Int64)) != SQLITE_OK {
					let reason = String(cString: sqlite3_errmsg(db))
					throw SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)
				}
			} else if value is String {
				if sqlite3_bind_text(statement, pindex, (value as! NSString).utf8String, -1, nil) != SQLITE_OK {
					let reason = String(cString: sqlite3_errmsg(db))
					throw SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)
				}
			} else if value is Double || value is Float {
				if sqlite3_bind_double(statement, pindex, value as! Double) != SQLITE_OK {
					let reason = String(cString: sqlite3_errmsg(db))
					throw SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)
				}
			}
			
		}
	}
	
	/**
	Resets the currently compiled statement and clears any bound parameters.
	
	*/
	private func clearStatementParameters() {
		resetStatement()
		if statement != nil {
			sqlite3_clear_bindings(statement)
		}
	}
	
	/**
	Compiles or resets a SQL statement and makes it ready to use with sqlite_step. If the previous query string is equal to this query string, then the statement isn't compiled, it is instead rest for use.
	
	- Throws: `SQLiteConnectorError.statementCouldNotBeCompiled(reason: reason)` if error occured compiling SQL statement. Reason gives error message from database pointer.
	
	*/
	private func prepare(_ statementString: String) throws {
		
		if prevRawQuery == statementString {
			//just reset it
			resetStatement()
		} else {
		
			finalize()
			
			if sqlite3_prepare_v2(db, statementString, -1, &statement, nil) != SQLITE_OK {
				let reason = String(cString: sqlite3_errmsg(db))
				throw SQLiteConnectorError.statementCouldNotBeCompiled(reason: reason)
			}
			
			prevRawQuery = statementString

		}
		
		
		
	}
	
	
	
	
	
	
}




