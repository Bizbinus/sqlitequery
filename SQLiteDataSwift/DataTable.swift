//
//  DataTable.swift
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
//

import Foundation

//DataTable holds data pulled from a sqlite database
class DataTable {
	
	//DataTable has a list of columns ( name and index )
	//has a list of rows with data for each column ( an array of arrays )
	
	var columns = [String:Int]()
	var rows:[DataRow] = [DataRow]()
	
	init() {
		
		
		
	}
	
	func appendColumn(_ columnName: String) throws {
		
		if columns[columnName] != nil {
			throw DataTableError.columnNameAlreadyExists(columnName: columnName)
		}
		
		columns[columnName] = columns.count
		
	}
	
	func newRow() -> DataRow {

		return DataRow(columns: columns.count, table: self)
		
	}
	
	func appendRow(_ row:DataRow) {
		
		rows.append(row)
	}
	
	
	
	
}

extension DataTable {
	
	enum DataTableError: Error {
		case columnNameAlreadyExists(columnName: String)
		case numberOfElementsInRowExccedsColumnLength(tableColumns: Int, rowColumns: Int)
	}
	
}

extension DataTable {
	
	class DataRow {
		
		private var elements = [Any?]()
		private weak var table:DataTable?
		
		var count:Int {
			return elements.count
		}
		
		init(columns: Int, table:DataTable) {
			
			elements = Array(repeating: nil, count: columns)
			
			self.table = table
			
		}
		
		
		
		subscript(index: Int) -> Any? {
			get {
				return elements[index]
			}
			set(newValue) {
				elements[index] = newValue
			}
		}
		
		subscript(key: String) -> Any? {
			get {
				return elements[table!.columns[key]!]
			}
			set (newValue) {
				elements[table!.columns[key]!] = newValue
			}
		}
		
		
		
	}
}


