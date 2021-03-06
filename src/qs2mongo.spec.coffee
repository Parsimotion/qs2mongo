_ = require("lodash")
should = require("should")
Qs2Mongo = require("./qs2mongo")
{ ObjectId } = require("mongodb")
Manual = require("./schemas/manual")
{ qs2mongo, req, multigetReq, multigetObjectIdReq, aDate, dateReq, aNumber, numberReq, anObjectId, objectIdReq } = {}
  
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
    anObjectId = "5919e3f5b89e9defa593734d"
    objectIdReq = query: anObjectIdField: anObjectId
    multigetObjectIdReq = query: ids: anObjectId

    schema = new Manual
      filterableBooleans: ["aBooleanField"]
      filterableDates: ["aDateField"]
      filterableNumbers: ["aNumberField"]
      filterableObjectIds: ["anObjectIdField"]
    
    qs2mongo = new Qs2Mongo {
      schema
      defaultSort: "_id"
    }

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

    it "should attach multiple filters to one field if not using strict", ->
      from = new Date("2017/06/03")
      to = new Date("2017/07/02")
      qs2mongo.parse
        query:
          aDateField__gte: from.toISOString()
          aDateField__lt: to.toISOString()
      .filters.should.eql
        aDateField: { $gte: from, $lt: to }

    it "should attach multiple filters to one field if using strict", ->
      from = new Date("2017/06/03")
      to = new Date("2017/07/02")
      qs2mongo.parse
        query:
          aDateField__gte: from.toISOString()
          aDateField__lt: to.toISOString()
        , strict: true
      .filters.should.eql
        aDateField: { $gte: from, $lt: to }

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
    
    it "should get multiple values in regex as and if not using strict", ->
      qs2mongo.parse query: name: ["juan", "jacobs"]
      .filters.should.eql
        name: /^(?=.*?juan)(?=.*?jacobs)/i

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

    it "should get objectid filters as objectids", ->
      qs2mongo.parse objectIdReq, strict: true
      .filters.should.eql
        anObjectIdField: new ObjectId anObjectId

    it "should get objectid filters as objectids without strict", ->
      qs2mongo.parse objectIdReq
      .filters.should.eql
        anObjectIdField: new ObjectId anObjectId

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

      it "should build multiget filters casting to proper type", ->
        qs2mongo.multigetIdField = "anObjectIdField"
        qs2mongo.parse multigetObjectIdReq
        .filters.should.eql
          anObjectIdField: $in: [ new ObjectId anObjectId ]

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
      
      describe "$in Operator", ->

        it "should build filters without strict", ->
          qs2mongo.parse {query: aField__in: "a,b,c"}
          .filters.should.eql
            aField: $in: ["a","b","c"]

        it "should build filters with strict", ->
          qs2mongo.parse {query: aField__in: "a,b,c"}, strict:true
          .filters.should.eql
          aField: $in: ["a","b","c"]
        
        it "should correctly build single item number filter with strict", ->
          qs2mongo.parse {query: aNumberField__in: "1"}, strict:true
          .filters.should.eql aNumberField: $in: [1]
        
        it "should correctly build single item number filter without strict", ->
          qs2mongo.parse {query: aNumberField__in: "1"}
          .filters.should.eql aNumberField: $in: [1]
      describe "type casting", ->  
        it "should cast $in operands to number when field es numeric without strict", ->
          qs2mongo.parse {query: aNumberField__in: "1,2,3"}
          .filters.should.eql
            aNumberField: $in: [1,2,3]
      
        it "should not cast $in operands to number when field is not numeric without strict", ->
          qs2mongo.parse {query: aField__in: "1,2,3"}
          .filters.should.eql
            aField: $in: ["1","2","3"]
        
        it "should cast $in operands to number when field is numeric", ->
          qs2mongo.parse {query: aNumberField__in: "1,2,3"}, strict: true
          .filters.should.eql
            aNumberField: $in: [1,2,3]
      
        it "should not cast $in operands to number when field is not numeric", ->
          qs2mongo.parse {query: aField__in: "1,2,3"}, strict: true
          .filters.should.eql
            aField: $in: ["1","2","3"]

        it "should cast each $or operand to its right type without strict", ->
          qs2mongo.parse {query: "aField,aNumberField": "123"}
          .filters.should.eql
            $or: [{aField:/123/i}, {aNumberField:123}]
        
        it "should cast each $or operand to its right type", ->
          qs2mongo.parse {query: "aField,aNumberField": "123"}, strict: true
          .filters.should.eql
            $or: [{aField:"123"}, {aNumberField:123}]
        
        it "should omit filter if operand has value outside its domain in $or operand ", ->
          qs2mongo.parse {query: "aField,aNumberField": "asdf"}, strict: true
          .filters.should.eql
            $or: [{aField:"asdf"}]
        
        it "should omit filter if date operand has value outside its domain in $or operand ", ->
          qs2mongo.parse {query: "aField,aDateField,anObjectIdField": "asdf"}, strict: true
          .filters.should.eql
            $or: [{aField:"asdf"}]

        it "should omit filter if date operand has value outside its domain in $or operand ", ->
          qs2mongo.parse {query: "aField,aDateField,anObjectIdField": anObjectId}, strict: true
          .filters.should.eql
            $or: [{aField:anObjectId}, { anObjectIdField: new ObjectId anObjectId }]
        
        it "should omit filter if operand has value outside its domain in $or operand without strict", ->
          qs2mongo.parse {query: "aField,aNumberField": "asdf"}
          .filters.should.eql
            $or: [{aField:/asdf/i}]
