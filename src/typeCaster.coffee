_ = require("lodash")
{ ObjectId } = require("mongodb")

module.exports = 
  class TypeCaster
    @operators: [ 'lt', 'gt','lte', 'gte','in','nin','eq' ] #TODO: Sacar esto de aca

    constructor: (opts) -> 
      _.assign @, opts
      #flowRight === compose
      @castFilters = 
        _.flowRight @_castNumberFilters, @_castDateFilters, @_castBooleanFilters

    _castObjectIdFilters: (query) =>
      @_transformFilters query, @objectIds, (it) -> new ObjectId(it)
    
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
      (value?.toLowerCase?() or _default?.toString()) is 'true'
