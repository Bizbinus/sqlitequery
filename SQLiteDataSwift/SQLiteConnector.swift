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
	
	
}

class SQLiteConnector {
	
	private var db: OpaquePointer?
	private var statement: OpaquePointer?
	private var dbFileUrl: URL?
	private var opened = false
	private var statementParameters = [String: Any]()
	
	init(databaseName: String) {
		
		let docDir = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
		
		dbFileUrl = docDir.appendingPathComponent(databaseName)
		
		print("database location: "+dbFileUrl!.absoluteString)
		
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
	
	/*
	func queryScalar(_ queryString: String) throws -> Any {
		
	
		try prepare(queryString)
		try prepareVariables()
		
		//let result = sqlite3_step(statement)
		
	
		
		
	}
*/
	
	private func prepareVariables() throws {
		
		//for each statementParam, apply the variable
		for (key, value) in statementParameters {
			
			
			let pindex = sqlite3_bind_parameter_index(statement, String(format: "$%@", key))

			if pindex == 0 {
				let reason = String(cString: sqlite3_errmsg(db))
				throw SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)
			}

			//for now only supporting int, text, and double
			//let valueType = type(of: value)

			if value is Int || value is Int32 {
				if sqlite3_bind_int(statement, pindex, value as! Int32) != SQLITE_OK {
					let reason = String(cString: sqlite3_errmsg(db))
					throw SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)
				}
			}
			else if value is Int64 {
				if sqlite3_bind_int64(statement, pindex, value as! Int64) != SQLITE_OK {
					let reason = String(cString: sqlite3_errmsg(db))
					throw SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)
				}
			}
			else if value is String {
				if sqlite3_bind_text(statement, pindex, value as! String, -1, nil) != SQLITE_OK {
					let reason = String(cString: sqlite3_errmsg(db))
					throw SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)
				}
			}
			else if value is Double {
				if sqlite3_bind_double(statement, pindex, value as! Double) != SQLITE_OK {
					let reason = String(cString: sqlite3_errmsg(db))
					throw SQLiteConnectorError.parameterCouldNotBeBound(reason: reason)
				}
			}
		}
	}
	
	func addParameter(name: String, value: Any)  {
		
		statementParameters[name] = value
		
		
		
	}
	
	func clearParameters() {
		
		if statement != nil {
			sqlite3_clear_bindings(statement)
			sqlite3_reset(statement)
		}
		statementParameters.removeAll(keepingCapacity: true)
		
	}

	func clean() {
		
		clearParameters()
		if statement != nil {
			sqlite3_finalize(statement)
			
		}
		
		statement = nil
	}
	
	
	private func prepare(_ statementString: String) throws {
		
		clean()
		
		if sqlite3_prepare(db, statementString, -1, &statement, nil) != SQLITE_OK {
			let reason = String(cString: sqlite3_errmsg(db))
			throw SQLiteConnectorError.statementCouldNotBeCompiled(reason: reason)
		}

		
	}
	
	
	
	
	
	
}




