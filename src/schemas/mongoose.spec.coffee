should = require("should")
_ = require("lodash")
mongoose = require("mongoose")
MyMongoose = require("./mongoose")
TestSchema = new mongoose.Schema
  dateField: Date
  numberField: Number
  booleanField: Boolean
  stringField: String
  objectField: {}
  arrayField: [Number]

{ myMongoose } = { }

describe "Mongoose schema", ->

  beforeEach ->
    myMongoose = new MyMongoose TestSchema

  it "should retrieve date fields correctly", ->
    myMongoose.dates().should.eql ['dateField']

  it "should retrieve number fields correctly", ->
    myMongoose.numbers().should.eql ['numberField']
  
  it "should retrieve boolean fields correctly", ->
    myMongoose.booleans().should.eql ['booleanField']