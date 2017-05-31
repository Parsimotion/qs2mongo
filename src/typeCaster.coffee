_ = require("lodash")

module.exports = 
  class TypeCaster
    @operators: [ 'lt', 'gt','lte', 'gte','in','nin','eq' ] #TODO: Sacar esto de aca

    constructor: (opts) -> _.assign @, opts
    
    _castBooleanFilters: (query) =>
      @_transformFilters query, @filterableBooleans, @_stringToBoolean

    _castDateFilters: (query) =>
      @_transformFilters query, @filterableDates, (it) -> new Date it.source or it

    _mergeWithOperators: (fields) =>
      _.flatMap fields, (field) =>
        TypeCaster.operators.map (it) => "#{field}__#{it}"
          .concat field
      #This has effect
    _transformFilters: (query, fields, transformation) =>
      filtersWithOperators = @_mergeWithOperators fields
      filtersWithOperators.forEach (field) =>
        query[field] = transformation query[field] if query[field]?

    _stringToBoolean: (value,_default) ->
      (value?.toLowerCase?() ? _default?.toString()) == 'true'

    castFilters: (filters) => 
      @_castBooleanFilters filters
      @_castDateFilters filters
