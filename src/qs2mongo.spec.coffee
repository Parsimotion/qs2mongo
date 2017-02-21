_ = require("lodash")
should = require("should")
Qs2Mongo = require("./qs2mongo")
{ qs2mongo, req } = {}
  
describe "Qs2Mongo", ->
  beforeEach ->
    req = 
      query:
        aField: "aValue"
        anotherField: "anotherValue"
        "fields,joinedByOr": "theOrValue"
        aBooleanField: "false"
        attributes:"aField,anotherField"
        limit:"10"
        offset:"20"
    qs2mongo = new Qs2Mongo filterableBooleans: ["aBooleanField"]

  it "should build everything in a query string", ->
    qs2mongo.parse req
    .should.eql
      filters: 
        aField: /aValue/i
        anotherField: /anotherValue/i
        aBooleanField: false
        $or: [
          { fields:/theOrValue/i }
          { joinedByOr: /theOrValue/i }
        ]
      projection: 
        aField:1
        anotherField:1
      options:
        limit: "10"
        offset: "20"
        sort: 
          _id: 1

  describe "Projection", ->
    it "should build projection", ->
      qs2mongo.parse req
      .projection.should.eql
        aField:1
        anotherField:1
  
  describe "Options", ->
    
    it "should build options with default sort", ->
      qs2mongo.parse req
      .options.should.eql
        limit: "10"
        offset: "20"
        sort: 
          _id: 1

    it "should build options with ascending sort", ->
      sort = "aField"
      _.assign req.query, { sort }
      qs2mongo.parse req
      .options.should.eql
        limit: "10"
        offset: "20"
        sort: 
          aField: 1

    it "should build options with descending sort", ->
      sort = "-aField"
      _.assign req.query, { sort }
      qs2mongo.parse req
      .options.should.eql
        limit: "10"
        offset: "20"
        sort: 
          aField: -1
  
  describe "Filters", ->

    it "should build filters with like ignore case if not using strict", ->
      qs2mongo.parse req
      .filters.should.eql
        aField: /aValue/i
        anotherField: /anotherValue/i
        aBooleanField: false
        $or: [
          { fields:/theOrValue/i }
          { joinedByOr: /theOrValue/i }
        ]

    it "should build filters with equal if using strict", ->
      qs2mongo.parse req, strict: true
      .filters.should.eql
        aField: "aValue"
        anotherField: "anotherValue"
        aBooleanField: false
        $or: [
          { fields: "theOrValue" }
          { joinedByOr: "theOrValue" }
        ]
