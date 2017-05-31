_ = require("lodash")
should = require("should")
Qs2Mongo = require("./qs2mongo")
{ qs2mongo, req, multigetReq, aDate, dateReq, aNumber, numberReq } = {}
  
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
    multigetReq = query: ids: ["unId","otroId"].join()
    aDate = new Date("1999/01/02")
    dateReq = query: aDateField: aDate.toISOString()
    aNumber = 42
    numberReq = query: aNumberField: aNumber.toString()
    qs2mongo = new Qs2Mongo 
      filterableBooleans: ["aBooleanField"]
      filterableDates: ["aDateField"]
      filterableNumbers: ["aNumberField"]
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
  
    it "When used as middleware should set mongo property in req object", (done)->
      qs2mongo.middleware req, _, ->
        req.mongo.should.eql 
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

        done()

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
    it "should get date filters as dates", ->
      qs2mongo.parse dateReq, strict: true
      .filters.should.eql
        aDateField: aDate

    it "should get date filters as dates if not strict", ->
      qs2mongo.parse dateReq
      .filters.should.eql
        aDateField: aDate

    it "should get number filters as numbers", ->
      qs2mongo.parse numberReq, strict: true
      .filters.should.eql
        aNumberField: aNumber


    describe "Multiget", ->
        
      it "should build multiget filters using strict", ->
        qs2mongo.parse multigetReq, strict: true
        .filters.should.eql
          _id: $in: ["unId","otroId"]

      it "should build multiget filters without using strict", ->
        qs2mongo.parse multigetReq
        .filters.should.eql
          _id: $in: ["unId","otroId"]

      it "should build multiget filters using a custom property", ->
        qs2mongo.multigetIdField = "custom_id"
        qs2mongo.parse multigetReq
        .filters.should.eql
          custom_id: $in: ["unId","otroId"]

    describe "Operators", ->

      it "should build filters with operator", ->
        qs2mongo.parse query: aField__gt: "23"
        .filters.should.eql
          aField: $gt: "23"

      it "should build filters with mixed operators", ->
        qs2mongo.parse 
          query: 
            aField__gt: "23"
            anotherField__lt: "42"
            yetAnotherField: "aValue"
        .filters.should.eql
          aField: $gt: "23"
          anotherField: $lt: "42"
          yetAnotherField: /aValue/i

      it "should build filters with date operator", ->
        qs2mongo.parse {query: aDateField__gt: aDate.toISOString()}, strict: true
        .filters.should.eql
          aDateField: $gt: aDate

      it "should build filters with date operator without strict", ->
        qs2mongo.parse {query: aDateField__gt: aDate.toISOString()}
        .filters.should.eql
          aDateField: $gt: aDate
      