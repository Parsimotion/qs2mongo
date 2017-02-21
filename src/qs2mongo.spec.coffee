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
        limit: "10"
        offset: "20"
    qs2mongo = new Qs2Mongo 
      filterableBooleans: ["aBooleanField"]
      defaultSort: "_id"

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
        limit: 10
        offset: 20
        sort: 
          _id: 1

  describe "Projection", ->
    it "should build projection", ->
      qs2mongo.parse req
      .projection.should.eql
        aField:1
        anotherField:1
  
  describe "Options", ->
    describe "Sort", ->

      it "should build options without any sort", ->
        qs2mongo.defaultSort = null
        { options } = qs2mongo.parse req
        should.not.exist options.sort

      it "should build options with default sort", ->
        qs2mongo.parse req
        .options.sort.should.eql
          _id: 1

      it "should build options with ascending sort", ->
        sort = "aField"
        _.assign req.query, { sort }
        qs2mongo.parse req
        .options.sort.should.eql
          aField: 1

      it "should build options with descending sort", ->
        sort = "-aField"
        _.assign req.query, { sort }
        qs2mongo.parse req
        .options.sort.should.eql
          aField: -1
    
    describe "Limit and offset", ->
    
      it "should build options with limit and offset when valid", ->
        qs2mongo.defaultSort = "_id"
        qs2mongo.parse req
        .options.should.containDeep
          limit: 10
          offset: 20

      it "should build options without limit and offset options", ->
        delete req.query.limit
        delete req.query.offset
        { options } = qs2mongo.parse req
        should.not.exist options.limit
        should.not.exist options.offset

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

    describe "Multiget", ->
      it "should build multiget filters using strict", ->
        multigetReq = query: ids: ["unId","otroId"].join()
        qs2mongo.parse multigetReq, strict: true
        .filters.should.eql
          _id: $in: ["unId","otroId"]

      it "should build multiget filters without using strict", ->
        multigetReq = query: ids: ["unId","otroId"].join()
        qs2mongo.parse multigetReq
        .filters.should.eql
          _id: $in: ["unId","otroId"]



    describe "Operators", ->

      it "should build filters with operator", ->
        qs2mongo.parse query: aField__gt: "23"
        .filters.should.eql
          aField: $gt: "23"

      it "should build filters with mixed operator", ->
        qs2mongo.parse 
          query: 
            aField__gt: "23"
            anotherField__lt: "42"
            yetAnotherField: "aValue"
        .filters.should.eql
          aField: $gt: "23"
          anotherField: $lt: "42"
          yetAnotherField: /aValue/i
