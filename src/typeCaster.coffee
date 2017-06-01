_ = require("lodash")

module.exports = 
  class TypeCaster
    @operators: [ 'lt', 'gt','lte', 'gte','in','nin','eq' ] #TODO: Sacar esto de aca

    constructor: (opts) -> 
      _.assign @, opts

    _castNumberFilters: (query) =>
      @_transformFilters query, @numbers, (it) -> Number(it)
    
    _castBooleanFilters: (query) =>
      @_transformFilters query, @booleans, @_stringToBoolean

    _castDateFilters: (query) =>
      @_transformFilters query, @dates, (it) -> new Date it.source or it

    _mergeWithOperators: (fields) =>
      _.flatMap fields, (field) =>
        TypeCaster.operators.map (it) => "#{field}__#{it}"
          .concat field
      #This has effect
    _transformFilters: (query, fields, transformation) =>
      filtersWithOperators = @_mergeWithOperators fields
      filtersWithOperators.forEach (field) =>
        query[field] = transformation query[field] if query[field]?
      query

    _stringToBoolean: (value,_default) ->
      (value?.toLowerCase?() ? _default?.toString()) == 'true'

    castFilters: (filters) => 
      @_compose(@_castNumberFilters, @_castDateFilters, @_castBooleanFilters) filters

    _compose: ->
      fns = arguments
      (result) ->
        _.forEachRight fns, (fn) ->
          result = fn result
        result