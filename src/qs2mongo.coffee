_ = require("lodash")

module.exports =
  class Qs2Mongo
    @defaultOmitableProperties: ['by', 'ids', 'attributes', 'offset', 'limit', 'sort' ]

    constructor: ({ @idField = "id", @multigetIdField = "_id", @filterableBooleans = [], @omitableProperties = Qs2Mongo.defaultOmitableProperties}) ->

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
      @_makeOrFilters filters

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

      @castBooleanFilters filters

      _(filters)
      .omit propertiesToOmit
      .merge idFilters
      .value()

    buildAttributes: (query) ->
      attributes = query.attributes.split ','
      _.zipObject attributes, _.times(attributes?.length, -> 1)

    stringToBoolean: (value,_default) ->
      (value?.toLowerCase?() ? _default?.toString()) == 'true'

    buildSearch: ({query}) =>
      search = _.omit query, @filterableBooleans.concat @omitableProperties
      booleans = _.pick query, @filterableBooleans
      @castBooleanFilters booleans

      _.merge booleans, @_asLikeIgnoreCase search

    _asLikeIgnoreCase: (search) ->
      _.reduce search, ((result, value, field) ->
        result[field] = new RegExp "#{value}", 'i'
        result
      ), {}

    _omitableProperties: => ['by', 'ids', 'attributes', 'offset', 'limit', 'sort' ]

    buildSort: (field = "_id") =>
      descending = field.startsWith("-")
      if descending
        field = field.substr 1
      { "#{field}": if descending then -1 else 1 }

    buildFilters: ({query}) =>
      filters = _.clone query
      propertiesToOmit = @omitableProperties
      idFilters = @buildIdFilters filters.ids

      @castBooleanFilters filters

      _(filters)
      .omit propertiesToOmit
      .merge idFilters
      .value()

    castBooleanFilters: (query) =>
      @filterableBooleans.forEach (field) =>
        query[field] = @stringToBoolean query[field] if query[field]?

    buildIdFilters: (ids) =>
      if ids?
        _({})
        .update @multigetIdField, -> $in: ids.split ","
        .value()
      else {}
