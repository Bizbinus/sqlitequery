//
//  SQLiteConnector.swift
//  SQLiteDataSwift
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


enum SQLiteConnectorError: Error
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

class SQLiteConnector {
	
	private var db: OpaquePointer?
	private var statement: OpaquePointer?
	private var dbFileUrl: URL?
	private var opened = false
	private var statementParameters = [String: Any]()
	private var prevRawQuery = ""
	
	var fileUrl: String? {
		if dbFileUrl != nil {
			return dbFileUrl!.absoluteString
		} else {
			return nil
		}
	}
	
	init(databaseName: String) {
		
		let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		
		dbFileUrl = docDir.appendingPathComponent(databaseName)
		
		
	}
	

	func isOpen() -> Bool {
		return opened
	}
	
	func close() {
		
		if (isOpen()) {
			sqlite3_close(db)
			opened = false
		}
		
	}
	
	//if database cannot be created or opened, throws an error
	func open() throws {
		
		if isOpen() {
			throw SQLiteConnectorError.databaseAlreadyOpen
		}
	
		if sqlite3_open(dbFileUrl!.absoluteString, &db) != SQLITE_OK {
			let reason = String(cString: sqlite3_errmsg(db))
			throw SQLiteConnectorError.databaseCouldNotBeOpenedOrCreated(reason: reason)
		}
		
		opened = true
		
	}
	
	func lastRowId() -> Int {
		return Int(sqlite3_last_insert_rowid(db))
	}
	
	func totalChanges() -> Int {
		let changes = Int(sqlite3_total_changes(statement))
		return changes
	}
	
	//executes the last compiled query
	func execute() throws {
		
		try execute(prevRawQuery)
		
	}
	
	//for executing inserts,deletes,updates
	func execute(_ queryString: String) throws {
		
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

	func executeScalar() throws -> Any? {
		return try executeScalar(prevRawQuery)
	}
	
	//for a query that returns a single value
	func executeScalar(_ queryString: String) throws -> Any? {
		
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
			} else if value is Double {
				if sqlite3_bind_double(statement, pindex, value as! Double) != SQLITE_OK {
					let reason = String(cString: sqlite3_errmsg(db))
					throw SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)
				}
			}
			
		}
	}
	
	func setParameter(name: String, value: Any)  {
		
		statementParameters[name] = value
	
		
	}
	
	func resetStatement() {
		if statement != nil {
			sqlite3_reset(statement)
		}
	}
	
	private func clearStatementParameters() {
		resetStatement()
		if statement != nil {
			sqlite3_clear_bindings(statement)
		}
	}
	
	func clearParameters() {
		
		clearStatementParameters()

		statementParameters = [String: Any]()

	}


	func finalize() {
		
		if statement != nil {
			sqlite3_finalize(statement)
			
		}
		
		statement = nil
		prevRawQuery = ""
	}

	func clear() {
		
		clearParameters()
		finalize()
	}
	
	
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




