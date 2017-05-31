_ = require("lodash")

module.exports =
  class Qs2Mongo
    @defaultOmitableProperties: ['by', 'ids', 'attributes', 'offset', 'limit', 'sort' ]
    @operators: [ 'lt', 'gt','lte', 'gte','in','nin','eq' ]

    constructor: ({ 
      @Schema,
      @defaultSort, 
      @idField = "id", 
      @multigetIdField = "_id", 
      @filterableBooleans = [], 
      @filterableDates = [], 
      @omitableProperties = Qs2Mongo.defaultOmitableProperties
    }) ->

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
        "#{name}": "$#{operator}": value.source or value
      rv = {}
      filtersWithOperators.forEach (it) => _.assign rv, it
      rv

    _makeOrFilters: (filters) =>
      _toCondition = _.curry (value, fieldNames) ->
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

    stringToBoolean: (value,_default) ->
      (value?.toLowerCase?() ? _default?.toString()) == 'true'

    buildSearch: ({query}) =>
      filters = _.clone query
      filterableDates = @_mergeWithOperators @filterableDates
      search = _.omit filters, 
        @filterableBooleans
        .concat @omitableProperties
        .concat filterableDates
      @_castFilters filters
      booleans = _.pick filters, @filterableBooleans
      dates = _.pick filters, filterableDates
      idFilters = @buildIdFilters filters.ids
      _.merge booleans, dates, idFilters, @_asLikeIgnoreCase search

    _asLikeIgnoreCase: (search) ->
      _.reduce search, ((result, value, field) ->
        result[field] = new RegExp "#{value}", 'i'
        result
      ), {}

    buildSort: (field = @defaultSort) =>
      if field?
        descending = field.startsWith("-")
        if descending
          field = field.substr 1
        { "#{field}": if descending then -1 else 1 }

    buildFilters: ({query}) =>
      filters = _.clone query
      propertiesToOmit = @omitableProperties
      idFilters = @buildIdFilters filters.ids

      @_castFilters filters
      
      _(filters)
      .omit propertiesToOmit
      .merge idFilters
      .value()

    castBooleanFilters: (query) =>
      @_transformFilters query, @filterableBooleans, @stringToBoolean

    castDateFilters: (query) =>
      @_transformFilters query, @filterableDates, (it) -> new Date it.source or it

    _castFilters: (filters) => 
      @castBooleanFilters filters
      @castDateFilters filters

    _mergeWithOperators: (fields) =>
      _.flatMap fields, (field) =>
        Qs2Mongo.operators.map (it)=> "#{field}__#{it}"
          .concat field
      #This has effect
    _transformFilters: (query, fields, transformation) =>
      filtersWithOperators = @_mergeWithOperators fields
      filtersWithOperators.forEach (field) =>
        query[field] = transformation query[field] if query[field]?

    buildIdFilters: (ids) =>
      if ids?
        _({})
        .update @multigetIdField, -> $in: ids.split ","
        .value()
      else {}
