//
//  DataTable.swift
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
//

import Foundation

/// DataTable holds data pulled from a sqlite database and makes it easy to loop through
public class DataTable {
	

	/**
	The columns for this DataTable that all DataRows adhere to.
	
	A DataRow uses this dictionary of columns to determing the element index being referenced.
	
	*/
	var columns = [String:Int]()
	
	/**
	The rows of data. Each row has a value for each column name.
	
	*/
	var rows:[DataRow] = [DataRow]()
	
	public init() {

	}
	
	/**
	Appends a new column name to this DataTable's columns store. The column index is sequentially assigned.
	
	- Parameter columnName: the name of the column to add.
	
	- Throws: - `DataTableError.columnNameAlreadyExists(columnName: columnName)` if columnName already exists. Column names must be unique.
	
	*/
	func appendColumn(_ columnName: String) throws {
		

		if columns[columnName] != nil {
			throw DataTableError.columnNameAlreadyExists(columnName: columnName)
		}
		
		columns[columnName] = columns.count
	
		
	}
	
	/**
	Creates a new DataRow the size of the number of columns in this table. The DataRow can then be populated with data and added to this DataTable.
	
	- Returns: a new DataRow that can be appended to this DataTable. DataRow has a weak reference to this DataTable in order to access this DataTables columns.
	
	*/
	func newRow() -> DataRow {

		return DataRow(columns: columns.count, table: self)
		
	}
	
	/**
	
	Appends a DataRow to this table.
	
	*/
	func appendRow(_ row:DataRow) {
		
		rows.append(row)
	}
	

	
	
}

/// List of errors that DataTable can throw
extension DataTable {
	
	public enum DataTableError: Error {
		case columnNameAlreadyExists(columnName: String)
		case numberOfElementsInRowExccedsColumnLength(tableColumns: Int, rowColumns: Int)
	}
	
}


extension DataTable {
	
	/// DataRow is a class used by DataTable to manage a list of data pulled from a sqlite query
	public class DataRow {
		
		/**
			Holdes an element for each column in this DataTable's column list
		*/
		private var elements = [Any?]()
		
		/**
			Weak reference to the DataTable that contains this DataRow.
		*/
		private weak var table:DataTable?
		
		/**
			Counts the number of elements ( columns ) in this DataRow
		*/
		var count:Int {
			return elements.count
		}
		
		/**
		Initializes a DataRow with number of columns and a reference to the DataTable that is creating this DataRow
		
		- Parameter columns: number of columns this DataRow has.
		- Parameter table: the DataTable this DataRow belongs to.
		
		*/
		init(columns: Int, table:DataTable) {
			
			elements = Array(repeating: nil, count: columns)
			
			self.table = table
			
		}
		
		
		/**
		Subscript so this DataRow's value can be retreived with an integer index, like DataRow[Int]
		
		- Parameter index: the index of the value to retreive in the element array.
	
		- Returns: The value stored in element at index
		*/
		subscript(index: Int) -> Any? {
			get {
				return elements[index]
			}
			set(newValue) {
				elements[index] = newValue
			}
		}
		
		/**
		Subscript so this DataRow's value can be retreived with a column name, like DataRow[String]. The columns variable on a DataTable is used to retreive this element at the columns index.
		
		- Parameter key: the column name needed to retreive the value in the elements list
		
		- Returns: The value stored in element at key
		*/
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


