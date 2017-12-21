//
//  DataTableTests.swift
//  SQLiteDataSwiftTests
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


import XCTest
@testable import SQLiteDataSwift

class DataTableTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
			
    }
    
    override func tearDown() {
			
        super.tearDown()
    }
    
	func testTable_newRowCountIsSameAsColumnsInTable() {
		
		let table = DataTable()
		
		try! table.appendColumn("column1")
		try! table.appendColumn("column2")
		try! table.appendColumn("column3")
		
		let row = table.newRow()
		
		XCTAssertTrue(row.count == table.columns.count)
		
		
	}
	
	func testTable_afterAddingColumnsCanAccessColumnIndexUsingKey() {
		
		let table = DataTable()
		try! table.appendColumn("column1")
		try! table.appendColumn("column2")
		try! table.appendColumn("column3")
		
		XCTAssertTrue(table.columns["column1"] == 0)
		XCTAssertTrue(table.columns["column2"] == 1)
		XCTAssertTrue(table.columns["column3"] == 2)
		
	}
	
	func testTable_shouldntBeAbleToAddDuplicateColumn() {
		
		let table = DataTable()
		try! table.appendColumn("column1")
	
		XCTAssertThrowsError(try table.appendColumn("column1"))
		
	}
	
	
	
	func testTable_addingRowsShouldBeAccessibleFromTableByKeyOrIndex() {
		
		
		let table = DataTable()
		try! table.appendColumn("id")
		try! table.appendColumn("name")
		try! table.appendColumn("description")
		
		let row1 = table.newRow()
		row1["id"] = 1
		row1["name"] = "Darrel"
		row1["description"] = "A Fisherman"

		table.appendRow(row1)
		
		let row2 = table.newRow()
		row2["id"] = 2
		row2["name"] = "Samantha"
		row2["description"] = "An Architect"
		
		table.appendRow(row2)
		
		XCTAssertTrue(table.rows[0]["id"] as! Int == 1)
		XCTAssertTrue(table.rows[0]["name"] as! String == "Darrel")
		XCTAssertTrue(table.rows[0]["description"] as! String == "A Fisherman")
		
		XCTAssertTrue(table.rows[0][0] as! Int == 1)
		XCTAssertTrue(table.rows[0][1] as! String == "Darrel")
		XCTAssertTrue(table.rows[0][2] as! String == "A Fisherman")
		
		XCTAssertTrue(table.rows[1]["id"] as! Int == 2)
		XCTAssertTrue(table.rows[1]["name"] as! String == "Samantha")
		XCTAssertTrue(table.rows[1]["description"] as! String == "An Architect")
		
		XCTAssertTrue(table.rows[1][0] as! Int == 2)
		XCTAssertTrue(table.rows[1][1] as! String == "Samantha")
		XCTAssertTrue(table.rows[1][2] as! String == "An Architect")
		
		
	}
	
	

    
	
    
}
