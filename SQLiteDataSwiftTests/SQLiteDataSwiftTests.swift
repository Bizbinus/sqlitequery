//
//  SQLiteDataSwiftTests.swift
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

class SQLiteDataSwiftTests: XCTestCase {
	
	var database: SQLiteConnector!
	
	
    override func setUp() {
        super.setUp()
			
			
			
			
			
			//this will create or open the file testdata
			database = SQLiteConnector(databaseName: "testdata")
			
			do {
				try FileManager.default.removeItem(at: URL(string: database.fileUrl!)!)
			} catch let error as NSError {
					print(error)
			}
			
			
	}
    
    override func tearDown() {
        super.tearDown()
			

			
			//delete the database to ensure our tests run the same everytime
			//if the database was never opened on a test, this will fail
			do {
				try FileManager.default.removeItem(at: URL(string: database.fileUrl!)!)
			} catch {
				
			}
			
    }
	
	
	func testDB_whenOpenIsOpen() {
		
		do {
			
			try database.open()
			
			XCTAssertTrue(database.isOpen())
			
			database.close()
			
		}
		catch {
			
			
		}
		
	}
	
	func testDB_whenOpenCantReopen() {
		
		
		XCTAssertNoThrow(try database.open())
		XCTAssertThrowsError(try database.open())
		
		database.close()
		
		
	}
	
	//This function creates it's own database to test a create error
	func testDB_whenCreatingDatabaseFailsThrowsError() {
		
		//create a new database here with an illegal file name
		
		let db = SQLiteConnector(databaseName: "")
		
		XCTAssertThrowsError(try db.open())
		
		db.close()
		
	}
	
	func testDB_whenDatabaseClosedNotIsOpen()
	{
		
			try! database.open()
		
			database.close()
		
		XCTAssertTrue(!database.isOpen())
		
		
	}
	
	func testDB_executingQueryOnClosedDatabaseThrowsError() {
		
		XCTAssertThrowsError(try database.execute("select count(*) from account"))
		XCTAssertThrowsError(try database.executeScalar("select count(*) from account"))
		
		
	}
	
	func testDB_createTableInsertWithBoundVarsSelectWithBoundVars() {
		
		try! database.open()
		
		
		try! database.execute("create table account(account_id integer primary key, name text, description text)")
		
		database.setParameter(name: "accountName", value: "john")
		database.setParameter(name: "accountDesc", value: "marketing and sales")
		

		try! database.execute("insert into account(name, description) values(@accountName, @accountDesc)")
		
		
		let accountID1 = database.lastRowId()
		
		database.setParameter(name: "accountName", value: "lisa")
		database.setParameter(name: "accountDesc", value: "obtuse deployment planning")
		
		try! database.execute()
		
		let accountID2 = database.lastRowId()
		
		database.clearParameters()
		
		database.setParameter(name: "accountID", value: accountID1)
		
		let name1 = try! database.executeScalar("select name from account where account_id=@accountID") as! String
		
		database.setParameter(name: "accountID", value: accountID2)
		
		let name2 = try! database.executeScalar() as! String
		
		
		let description2 = try! database.executeScalar("select description from account where account_id=@accountID") as! String
		
		database.setParameter(name: "accountID", value: accountID1)
		
		let description1 = try! database.executeScalar() as! String
		
		XCTAssertTrue(name1 == "john")
		XCTAssertTrue(description1 == "marketing and sales")
		

		XCTAssertTrue(name2 == "lisa")
		XCTAssertTrue(description2 == "obtuse deployment planning")
		
		database.clear()
		
		//cleanup
		try! database.execute("drop table account")
	
		database.close()
		
		
	}
	
	func testDB_canCreateTableWithExecuteInsertDataWithExecuteValidateWithExecuteScalarDeleteWithExecute() {
		
		try! database.open()
		
		try! database.execute("create table account(account_id integer primary key, name text, description text)")
		
		try! database.execute("insert into account(name, description) values('john', 'marketing and sales')")
		
		let accountID1 = database.lastRowId()
		
		XCTAssertTrue(accountID1 == 1)
		
		try! database.execute("insert into account(name, description) values('lisa', 'obtuse deployment planning')")
		
		let accountID2 = database.lastRowId()
		
		XCTAssertTrue(accountID2 == 2)
		
		let name1 = try! database.executeScalar("select name from account where account_id=1") as! String
		let description1 = try! database.executeScalar("select description from account where account_id=1") as! String
		
		XCTAssertTrue(name1 == "john")
		XCTAssertTrue(description1 == "marketing and sales")
		
		let name2 = try! database.executeScalar("select name from account where account_id=2") as! String
		let description2 = try! database.executeScalar("select description from account where account_id=2") as! String
		
		XCTAssertTrue(name2 == "lisa")
		XCTAssertTrue(description2 == "obtuse deployment planning")
		
		try! database.execute("delete from account")
		
		XCTAssertTrue(try! database.executeScalar("select count(*) from account") as! Int == 0)
		
		database.clear()
		
		try! database.execute("drop table account")
		
		database.close()
		
		
	}
    
    func testPerformanceExample() {
			
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
