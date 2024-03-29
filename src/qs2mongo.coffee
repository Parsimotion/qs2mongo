_ = require("lodash")
TypeCaster = require("./typeCaster")
schemas = require("./schemas")
module.exports =
  class Qs2Mongo

    @Schemas: schemas
    
    @MongooseSchema: (schema, options = {}) ->
      new @ _.merge { schema: new schemas.Mongoose schema }, options

    @ManualSchema: (fields = {}, options = {}) ->
      new @ _.merge { schema: new schemas.Manual fields }, options

    @defaultOmitableProperties: ['by', 'ids', 'attributes', 'offset', 'limit', 'sort' ]
    @operators: [ 'lt', 'gt','lte', 'gte','in','nin','eq', 'ne', 'exists' ]

    constructor: ({ 
      @schema
      @defaultSort
      @idField = "id"
      @multigetIdField = "_id"
      @omitableProperties = Qs2Mongo.defaultOmitableProperties
    }) ->
      @typeCaster = new TypeCaster {
        booleans: @schema.booleans()
        dates: @schema.dates()
        numbers: @schema.numbers()
        objectIds: @schema.objectIds()
        @omitableProperties
      }

    middleware: (req, res, next) ->
      mongo = @parse req
      _.assign req, { mongo }
      next()
    
    parse: (req, { strict } = {}) =>
      { query: {limit, offset,sort} } = req
      filters = @_getFilters_ req, strict
      projection = @buildAttributes req.query
      options = @buildOptions req
      { filters, projection, options }
    
    buildOptions: ({query: {limit, offset, sort}}) =>
      [ parsedLimit, parsedOffset ] = [limit,offset].map (it) => parseInt it
      _.omitBy 
        limit: if !isNaN parsedLimit then parsedLimit
        offset: if !isNaN parsedOffset then parsedOffset
        sort: @buildSort(sort)
      , _.isUndefined

    _getFilters_: (req, strict) =>
      filters = if strict then @buildFilters(req)
      else @buildSearch(req)
      filtersWithUnparsedOperators = @_makeOrFilters filters
      @_parseOperators filtersWithUnparsedOperators

    _parseOperators: (filtersWithUnparsedOperators) =>
      filtersWithOperators = _.map filtersWithUnparsedOperators, (value,field) =>
        operator = _.find Qs2Mongo.operators, (operator) => _.endsWith field, "__#{operator}"
        return {"#{field}":value} unless operator?
        name = field.replace "__#{operator}", ""
        @_parseOperator name, operator, value
      rv = {}
      filtersWithOperators.forEach (it) => _.merge rv, it
      @_castOrOperands rv
    
    _castOrOperands: (filters) => 
      if filters["$or"]
        filters["$or"] = _.compact filters["$or"].map (filter) => 
          name = _.head(_.keys(filter))
          value = @_castByName name, filter[name]
          "#{name}": value unless _.isUndefined value

      filters

    _parseOperator: (name, operator, operand) =>
      argument = operand.source or operand
      if operator in ["in","nin"] 
        if _.isString argument
          argument = argument.split(',').map (it) => @_castByName name, it
        else 
          argument = _.castArray argument

      "#{name}": "$#{operator}": argument

    _makeOrFilters: (filters) =>
      _toCondition = _.curry (value, fieldNames) =>
        fields = fieldNames.split(',')
        switch fields.length
          when 1 then "#{fields[0]}": value
          else "$or" : fields.map _toCondition value

      _.merge {}, _.map(filters, _toCondition)...

    buildFilters: ({query}) =>
      filters = _.clone query
      propertiesToOmit = @omitableProperties
      idFilters = @buildIdFilters filters.ids
      @_castFilters filters

      _(filters)
      .omit propertiesToOmit
      .merge idFilters
      .value()

    buildAttributes: (query) ->
      attributes = query.attributes?.split ','
      _.zipObject attributes, _.times(attributes?.length, -> 1)

    buildSearch: ({query}) =>
      filters = _.clone query
      
      casteableFields = _.flatMap ["dates","numbers","objectIds","booleans"], (getter) =>
        @_mergeWithOperators @schema[getter]()  
      
      search = _.omit filters, casteableFields, @omitableProperties

      @_castFilters filters

      castedFilters = _.pick filters, casteableFields
      idFilters = @buildIdFilters filters.ids
      
      _.merge castedFilters, idFilters, @_asLikeIgnoreCase search

    _mergeWithOperators: (fields) =>
      _.flatMap fields, (field) =>
        Qs2Mongo.operators.map (it)=> "#{field}__#{it}"
          .concat field

    _asLikeIgnoreCase: (search) =>
      _.reduce search, ((result, value, field) =>
        regex = if _.isArray(value) then @_arrayAndRegex(value) else value
        result[field] = new RegExp "#{regex}", 'i'
        result
      ), {}

    _arrayAndRegex: (array) ->
      "^" + array.map((it) => "(?=.*?#{it})").join("");

    buildSort: (field = @defaultSort) =>
      if field?
        descending = field.startsWith("-")
        if descending
          field = field.substr 1
        { "#{field}": if descending then -1 else 1 }

    _castByName: (name, value) => @_castFilters("#{name}": value)[name]
    
    _castFilters: (filters) => @typeCaster.castFilters filters

    buildIdFilters: (ids) =>
      if ids?
        $in = ids.split(",").map (id) => @_castByName @multigetIdField, id
        _({})
        .update @multigetIdField, => { $in }
        .value()
      else {}
