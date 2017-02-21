_ = require("lodash")
should = require("should")
Qs2Mongo = require("./qs2mongo")
{ qs2mongo } = {}
req = 
  query:
    aField: "aValue"
    anotherField: "anotherValue"
    "fields,joinedByOr": "theOrValue"
    aBooleanField: "false"
    attributes:"aField,anotherField"
    limit:"10"
    offset:"20"
  
describe "Qs2Mongo", ->
  beforeEach ->
    qs2mongo = new Qs2Mongo filterableBooleans: ["aBooleanField"]

  describe "When not using strict", ->
    it "should build filters with like ignore case, projection and options", ->
      qs2mongo.parse req
      .should.eql
        filters: 
          aField: /aValue/i
          anotherField: /anotherValue/i
          aBooleanField: false
          $or: [
            { fields:/theOrValue/i }
            {joinedByOr: /theOrValue/i }
            ]
        projection: 
          aField:1
          anotherField:1
        options:
          limit: "10"
          offset: "20"
          sort: 
            _id: 1

  describe "When using strict", ->
    it "should build filters with equal, projection and options", ->
      qs2mongo.parse req, strict: true
      .should.eql
        filters: 
          aField: "aValue"
          anotherField: "anotherValue"
          aBooleanField: false
          $or: [
            { fields: "theOrValue" }
            {joinedByOr: "theOrValue" }
            ]
        projection:
          aField:1
          anotherField:1
        options:
          limit: "10"
          offset: "20"
          sort: 
            _id: 1